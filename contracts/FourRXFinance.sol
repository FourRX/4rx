// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Insurance.sol";


contract FourRXFinance is Insurance {

    constructor(address fourRXTokenAddress) public {
        fourRXToken = IERC20(fourRXTokenAddress);

        refPoolBonuses.push(2000);
        refPoolBonuses.push(1700);
        refPoolBonuses.push(1400);
        refPoolBonuses.push(1100);
        refPoolBonuses.push(1000);
        refPoolBonuses.push(700);
        refPoolBonuses.push(600);
        refPoolBonuses.push(500);
        refPoolBonuses.push(400);
        refPoolBonuses.push(300);
        refPoolBonuses.push(200);
        refPoolBonuses.push(100);

        sponsorPoolBonuses.push(3000);
        sponsorPoolBonuses.push(2000);
        sponsorPoolBonuses.push(1200);
        sponsorPoolBonuses.push(1000);
        sponsorPoolBonuses.push(800);
        sponsorPoolBonuses.push(700);
        sponsorPoolBonuses.push(600);
        sponsorPoolBonuses.push(400);
        sponsorPoolBonuses.push(200);
        sponsorPoolBonuses.push(100);

        _resetPools();

        poolCycle = 0;
    }

    function deposit(uint amount, address uplinkAddress, uint uplinkStakeId) external {
        require(
            (users[uplinkAddress].wallet != address(0) && users[uplinkAddress].stakes[uplinkStakeId].active) ||
            uplinkAddress == address(0)
        ); // Either uplink must be registered and be a active deposit, 0 address

        User storage user = users[msg.sender];

        if (users[msg.sender].stakes.length > 0) {
            require(amount >= users[msg.sender].stakes[user.stakes.length - 1].deposit.mul(2)); // deposit amount must be greater 2x then last deposit
        }

        require(fourRXToken.transferFrom(msg.sender, address(this), amount));

        drawPool(); // Draw old pool if qualified, and we're pretty sure that this stake is going to be created

        uint depositReward = _calcDepositRewards(amount);

        Stake memory stake;

        user.wallet = msg.sender;

        stake.id = user.stakes.length;
        stake.active = true;
        stake.interestCountFrom = block.timestamp;
        stake.holdFrom = block.timestamp;

        stake.deposit = amount.sub(_calcPercentage(amount, LP_FEE_BP)).add(depositReward); // Deduct LP Commission + add deposit rewards
        stake.uplink.uplinkAddress = uplinkAddress;
        stake.uplink.uplinkStakeId = uplinkStakeId;

        stake.sponsorPool.cycle = poolCycle;
        stake.sponsorPool.amount = amount;

        _updateSponsorPoolUsers(user, stake);

        _distributeReferralReward(amount, stake);

        user.stakes.push(stake);

        refPoolBalance = refPoolBalance.add(_calcPercentage(amount, REF_POOL_FEE_BP));
        sponsorPoolBalance = sponsorPoolBalance.add(_calcPercentage(amount, SPONSOR_POOL_FEE_BP));

        fourRXToken.transfer(devAddress, _calcPercentage(amount, DEV_FEE_BP));

        uint currentContractBalance = fourRXToken.balanceOf(address(this));

        if (currentContractBalance > maxContractBalance) {
            maxContractBalance = currentContractBalance;
        }

        totalDeposits = totalDeposits.add(amount);
        totalStakes = totalStakes.add(1);
        totalActiveStakes = totalActiveStakes.add(1);
        totalDepositRewards = totalDepositRewards.add(depositReward);

        emit Deposit(msg.sender, uplinkAddress, amount);
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
        stake.lastWithdrawalAt = block.timestamp;
        stake.holdFrom = block.timestamp;

        stake.penalty = stake.penalty.add(penalty);

        totalPenalty = totalPenalty.add(penalty);

        if (stake.withdrawn >= _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP)) {
            stake.active = false; // if stake has withdrawn equals to or more then the max amount, then mark stake in-active
            totalActiveStakes = totalActiveStakes.sub(1);
        }

        _checkForBaseInsuranceTrigger();

        totalWithdrawn = totalWithdrawn.add(availableAmount);

        emit Withdraw(user.wallet, availableAmount);
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
        availableAmount = availableAmount.sub(withdrawn); // @todo: discuss this new implementation with Assaf

        fourRXToken.transfer(user.wallet, availableAmount);

        stake.active = false;
        stake.withdrawn = stake.withdrawn.add(availableAmount);
        stake.penalty = stake.penalty.add(penaltyAmount);

        totalActiveStakes = totalActiveStakes.sub(1);
        totalExited = totalExited.add(1);

        totalWithdrawn = totalWithdrawn.add(availableAmount);
        totalPenalty = totalPenalty.add(penaltyAmount);

        emit Exited(user.wallet);
    }

    function insureStake(uint stakeId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender);
        Stake storage stake = user.stakes[stakeId];
        _insureStake(stake);
    }

    function getUser(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }

    function getPoolInfo() external view returns (uint, uint, uint, uint, PoolUser[10] memory, PoolUser[12] memory) {
        return (poolDrewAt, poolCycle, sponsorPoolBalance, refPoolBalance, sponsorPoolUsers, refPoolUsers);
    }

    function getContractInfo() external view returns (uint, bool, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (maxContractBalance, isInInsuranceState, totalDeposits, totalWithdrawn, totalStakes, totalActiveStakes, totalRefRewards, totalRefPoolRewards, totalSponsorPoolRewards, totalDepositRewards, totalPenalty, totalExited);
    }
}
