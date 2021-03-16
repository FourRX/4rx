// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Insurance.sol";

/// @title 4RX Finance Staking DAPP Contract
/// @notice Available functionality: Deposit, Withdraw, ExitProgram, Insure Stake
/// @dev
contract FourRXFinance is Insurance {

    constructor(address fourRXTokenAddress) public {
        fourRXToken = IERC20(fourRXTokenAddress);

        // Ref Bonus // 12 Max Participants
        refPoolBonuses.push(2000); // 20%
        refPoolBonuses.push(1700); // 17%
        refPoolBonuses.push(1400); // 14%
        refPoolBonuses.push(1100); // 11%
        refPoolBonuses.push(1000); // 10%
        refPoolBonuses.push(700); // 7%
        refPoolBonuses.push(600); // 6%
        refPoolBonuses.push(500); // 5%
        refPoolBonuses.push(400); // 4%
        refPoolBonuses.push(300); // 3%
        refPoolBonuses.push(200); // 2%
        refPoolBonuses.push(100); // 1%

        // Sponsor Pool // 10 Max Participants
        sponsorPoolBonuses.push(3000); // 30%
        sponsorPoolBonuses.push(2000); // 20%
        sponsorPoolBonuses.push(1200); // 12%
        sponsorPoolBonuses.push(1000); // 10%
        sponsorPoolBonuses.push(800); // 8%
        sponsorPoolBonuses.push(700); // 7%
        sponsorPoolBonuses.push(600); // 6%
        sponsorPoolBonuses.push(400); // 4%
        sponsorPoolBonuses.push(200); // 2%
        sponsorPoolBonuses.push(100); // 1%

        _resetPools();

        poolCycle = 0;
    }

    function deposit(uint amount, address uplinkAddress, uint8 uplinkStakeId, uint16 sponsorPoolPrev, uint16 refPoolPrev, uint16 refPoolNewPrev, uint16 refPoolCurrent) external {
        // 2k
        require(
            uplinkAddress == address(0) ||
            (users[uplinkAddress].wallet != address(0) && users[uplinkAddress].stakes[uplinkStakeId].active)
        ); // Either uplink must be registered and be a active deposit, 0 address

        User storage user = users[msg.sender];
        // 1k
        if (users[msg.sender].stakes.length > 0) {
            require(amount >= users[msg.sender].stakes[user.stakes.length - 1].deposit.mul(2)); // deposit amount must be greater 2x then last deposit
        }
        // 30k
        require(fourRXToken.transferFrom(msg.sender, address(this), amount));
        // 66k
        drawPool(); // Draw old pool if qualified, and we're pretty sure that this stake is going to be created

        uint depositReward = _calcDepositRewards(amount);

        Stake memory stake;

        user.wallet = msg.sender;

        stake.id = uint8(user.stakes.length);
        stake.active = true;
        stake.interestCountFrom = uint32(block.timestamp);
        stake.holdFrom = uint32(block.timestamp);

        stake.deposit = amount.sub(_calcPercentage(amount, LP_FEE_BP)).add(depositReward); // Deduct LP Commission + add deposit rewards

        // 33k
        _updateSponsorPoolUsers(user, stake, sponsorPoolPrev);
        // 54k
        if (uplinkAddress != address(0)) {
            _distributeReferralReward(amount, stake, uplinkAddress, uplinkStakeId, refPoolPrev, refPoolNewPrev, refPoolCurrent);
        }

        user.stakes.push(stake);
        // 12k
        refPoolBalance = refPoolBalance.add(_calcPercentage(amount, REF_POOL_FEE_BP));
        // 20k
        sponsorPoolBalance = sponsorPoolBalance.add(_calcPercentage(amount, SPONSOR_POOL_FEE_BP));

        // 14k
        devBalance = devBalance.add(_calcPercentage(amount, DEV_FEE_BP));

        uint currentContractBalance = fourRXToken.balanceOf(address(this));

        if (currentContractBalance > maxContractBalance) {
            maxContractBalance = currentContractBalance;
        }

        // 54k
        totalDepositRewards = totalDepositRewards.add(depositReward);

        emit Deposit(msg.sender, amount, uplinkAddress, uplinkStakeId);
    }


    function balanceOf(address _userAddress, uint stakeId) external view returns (uint) {
        require(users[_userAddress].wallet == _userAddress);
        User memory user = users[_userAddress];

        return _calcRewards(user.stakes[stakeId]).sub(user.stakes[stakeId].withdrawn);
    }

    function withdraw(uint stakeId) external {
        User storage user = users[msg.sender];
        Stake storage stake = user.stakes[stakeId];
        require(user.wallet == msg.sender && stake.active); // stake should be active

        require(stake.lastWithdrawalAt + 1 days < block.timestamp); // we only allow one withdrawal each day

        uint availableAmount = _calcRewards(stake).sub(stake.withdrawn).sub(stake.penalty);

        require(availableAmount > 0);

        uint penalty = _calcPenalty(stake, availableAmount);

        if (penalty == 0) {
            availableAmount = availableAmount.sub(_calcPercentage(stake.deposit, REWARD_THRESHOLD_BP)); // Only allow withdrawal if available is more then 10% of base

            uint maxAllowedWithdrawal = _calcPercentage(stake.deposit, MAX_WITHDRAWAL_OVER_REWARD_THRESHOLD_BP);

            if (availableAmount > maxAllowedWithdrawal) {
                availableAmount = maxAllowedWithdrawal;
            }
        }

        if (isInInsuranceState) {
            availableAmount = _getInsuredAvailableAmount(stake, availableAmount);
        }

        availableAmount = availableAmount.sub(penalty);

        fourRXToken.transfer(user.wallet, availableAmount);

        stake.withdrawn = stake.withdrawn.add(availableAmount);
        stake.lastWithdrawalAt = uint32(block.timestamp);
        stake.holdFrom = uint32(block.timestamp);

        stake.penalty = stake.penalty.add(penalty);

        if (stake.withdrawn >= _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP)) {
            stake.active = false; // if stake has withdrawn equals to or more then the max amount, then mark stake in-active
        }

        _checkForBaseInsuranceTrigger();

        emit Withdrawn(user.wallet, availableAmount);
    }

    function exitProgram(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender);
        Stake storage stake = user.stakes[stakeId];
        uint availableAmount = stake.deposit;
        uint penaltyAmount = _calcPercentage(stake.deposit, EXIT_PENALTY_BP);

        availableAmount = availableAmount.sub(penaltyAmount);

        uint withdrawn = stake.withdrawn.add(stake.penalty);
        require(withdrawn <= availableAmount);
        availableAmount = availableAmount.sub(withdrawn);

        fourRXToken.transfer(user.wallet, availableAmount);

        stake.active = false;
        stake.withdrawn = stake.withdrawn.add(availableAmount);
        stake.penalty = stake.penalty.add(penaltyAmount);

        totalExited = totalExited.add(1);

        emit Exited(user.wallet, stakeId, availableAmount);
    }

    function insureStake(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender);
        Stake storage stake = user.stakes[stakeId];
        _insureStake(user.wallet, stake);
    }

    // Getters

    function getUser(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }


    function getContractInfo() external view returns (uint, bool, uint, uint) {
        return (maxContractBalance, isInInsuranceState, totalDepositRewards, totalExited);
    }

    function withdrawDevFee(address withdrawingAddress, uint amount) external {
        require(msg.sender == devAddress);
        require(amount <= devBalance);
        fourRXToken.transfer(withdrawingAddress, amount);
        devBalance = devBalance.sub(amount);
    }

    function updateDevAddress(address newDevAddress) external {
        require(msg.sender == devAddress);
        devAddress = newDevAddress;
    }
}
