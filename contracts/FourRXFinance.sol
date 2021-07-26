// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./Insurance.sol";

/// @title 4RX Finance Staking DAPP Contract
/// @notice Available functionality: Deposit, Withdraw, ExitProgram, Insure Stake
contract FourRXFinance is Insurance {

    constructor(address _devAddress, address fourRXTokenAddress) public {
        devAddress = _devAddress;
        fourRXToken = IERC20(fourRXTokenAddress);

        refPoolBonuses = [2000, 1700, 1400, 1100, 1000, 700, 600, 500, 400, 300, 200, 100];
        sponsorPoolBonuses = [3000, 2000, 1200, 1000, 800, 700, 600, 400, 200, 100];

        _resetPools();

        poolCycle = 0;

        isInInsuranceState = false;
    }

    function deposit(uint amount, address uplinkAddress, uint8 uplinkStakeId) external {
        require(
            uplinkAddress == address(0) ||
            (users[uplinkAddress].wallet != address(0) && users[uplinkAddress].stakes[uplinkStakeId].active)
        , 'FF: 1100'); // Either uplink must be registered and be a active deposit or 0 address

        User storage user = users[msg.sender];

        if (users[msg.sender].stakes.length > 0) {
            require(amount >= users[msg.sender].stakes[user.stakes.length - 1].deposit.mul(2), 'FF: 1101'); // deposit amount must be greater 2x then last deposit
        }

        require(fourRXToken.transferFrom(msg.sender, address(this), amount), 'FF: 1102');

        drawPool(); // Draw old pool if qualified, and we're pretty sure that this stake is going to be created

        uint depositReward = _calcDepositRewards(amount);

        Stake memory stake;

        user.wallet = msg.sender;

        stake.id = uint8(user.stakes.length);
        stake.active = true;
        stake.interestCountFrom = uint32(block.timestamp);
        stake.holdFrom = uint32(block.timestamp);

        stake.origDeposit = amount;
        stake.deposit = amount.sub(_calcPercentage(amount, LP_FEE_BP)); // Deduct LP Commission
        stake.rewards = depositReward;

        _updateSponsorPoolUsers(user, stake);

        if (uplinkAddress != address(0)) {
            _distributeReferralReward(amount, stake, uplinkAddress, uplinkStakeId);
        }

        user.stakes.push(stake);

        refPoolBalance = refPoolBalance.add(_calcPercentage(amount, REF_POOL_FEE_BP));

        sponsorPoolBalance = sponsorPoolBalance.add(_calcPercentage(amount, SPONSOR_POOL_FEE_BP));

        devBalance = devBalance.add(_calcPercentage(amount, DEV_FEE_BP));

        uint currentContractBalance = fourRXToken.balanceOf(address(this));

        if (currentContractBalance > maxContractBalance) {
            maxContractBalance = currentContractBalance;
        }

//        totalDepositRewards = totalDepositRewards.add(depositReward);

        emit Deposit(msg.sender, amount, stake.id,  uplinkAddress, uplinkStakeId);
    }


    function balanceOf(address _userAddress, uint stakeId) public view returns (uint) {
        require(users[_userAddress].wallet == _userAddress, 'FF: 1103');
        User memory user = users[_userAddress];

        return _calcRewards(user.stakes[stakeId]).sub(user.stakes[stakeId].withdrawn);
    }

    function withdraw(uint stakeId) external {
        User storage user = users[msg.sender];
        Stake storage stake = user.stakes[stakeId];
        require(user.wallet == msg.sender && stake.active, 'FF: 1104'); // stake should be active

        require(stake.lastWithdrawalAt + 1 days < block.timestamp, 'FF: 1105'); // we only allow one withdrawal each day

        uint availableAmount = _calcRewards(stake).sub(stake.withdrawn).sub(stake.penalty);

        require(availableAmount > 0, 'FF: 1106');

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

        stake.withdrawn = stake.withdrawn.add(availableAmount);
        stake.lastWithdrawalAt = uint32(block.timestamp);
        stake.holdFrom = uint32(block.timestamp);

        stake.penalty = stake.penalty.add(penalty);

        if (stake.withdrawn >= _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP)) {
            stake.active = false; // if stake has withdrawn equals to or more then the max amount, then mark stake in-active
        }

        _checkForBaseInsuranceTrigger();

        fourRXToken.transfer(user.wallet, availableAmount);

        emit Withdrawn(user.wallet, availableAmount);
    }

    function exitProgram(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender, 'FF: 1107');
        Stake storage stake = user.stakes[stakeId];

        require(stake.active, 'FF: 1108');
        require(_calcDays(stake.interestCountFrom, block.timestamp) <= 150, 'FF: 1109'); // No exit after 150 days

        uint penaltyAmount = _calcPercentage(stake.origDeposit, EXIT_PENALTY_BP);
        uint balance = balanceOf(msg.sender, stakeId);

        uint availableAmount = stake.deposit + balance - penaltyAmount; // (deposit - entry fee + (rewards - withdrawn) - penalty)

        if (availableAmount > 0) {
            fourRXToken.transfer(user.wallet, availableAmount);
            stake.withdrawn = stake.withdrawn.add(availableAmount);
        }

        stake.active = false;
        stake.penalty = stake.penalty.add(penaltyAmount);

//        totalExited = totalExited.add(1);

        emit Exited(user.wallet, stakeId, availableAmount > 0 ? availableAmount : 0);
    }

    function insureStake(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender, 'FF: 1110');
        Stake storage stake = user.stakes[stakeId];
        _insureStake(user.wallet, stake);
    }

    // Getters

    function getUser(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }

    function getContractInfo() external view returns (uint, bool) {
        return (maxContractBalance, isInInsuranceState);
    }

    function withdrawDevFee(address withdrawingAddress, uint amount) external {
        require(msg.sender == devAddress, 'FF: 1111');
        require(amount <= devBalance, 'FF: 1112');
        devBalance = devBalance.sub(amount);
        fourRXToken.transfer(withdrawingAddress, amount);
    }

    function updateDevAddress(address newDevAddress) external {
        require(msg.sender == devAddress, 'FF: 1113');
        devAddress = newDevAddress;
    }
}
