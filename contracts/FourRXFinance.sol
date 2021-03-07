// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
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
    }

    function deposit(uint amount, address uplinkAddress, uint uplinkId) external {
        require((users[uplinkAddress].registered && users[uplinkAddress].investments[uplinkId].active) || uplinkAddress == address(0)); // Either uplink must be registered and be a active deposit, 0 address

        User storage user = users[msg.sender];

        if (users[msg.sender].investments.length > 0) {
            require(amount > users[msg.sender].investments[user.investments.length - 1].deposit.mul(2)); // deposit amount must be greater 2x then last deposit
        }

        require(fourRXToken.transferFrom(msg.sender, address(this), amount));

        uint depositReward = _calcDepositRewards(amount);

        Investment memory investment;

        user.wallet = msg.sender;
        user.registered = true;

        investment.id = user.investments.length;
        investment.active = true;
        investment.interestCountFrom = block.timestamp;
        investment.holdFrom = block.timestamp;

        investment.deposit = amount.sub(_calcPercentage(amount, lpCommission)).add(depositReward); // Deduct LP Commission + add deposit rewards
        investment.uplink.uplinkAddress = uplinkAddress;
        investment.uplink.uplinkInvestmentId = uplinkId;

        investment.sponsorPool.cycle = poolCycle;
        investment.sponsorPool.amount = amount;

        _updateSponsorPoolUsers(user, investment);

        _distributeReferralReward(amount, investment);

        user.investments.push(investment);

        refPoolBalance = refPoolBalance.add(_calcPercentage(amount, depositRefPoolCommission));
        sponsorPoolBalance = sponsorPoolBalance.add(_calcPercentage(amount, depositSponsorPoolCommission));

        drawPool();

        fourRXToken.transfer(devAddress, _calcPercentage(amount, devCommission));

        uint currentContractBalance = fourRXToken.balanceOf(address(this));

        if (currentContractBalance > maxContractBalance) {
            maxContractBalance = currentContractBalance;
        }

        totalDeposits = totalDeposits.add(amount);
        totalInvestments = totalInvestments.add(1);
        totalActiveInvestments = totalActiveInvestments.add(1);
        totalDepositRewards = totalDepositRewards.add(depositReward);

        emit Deposit(msg.sender, uplinkAddress, amount);
    }


    function balanceOf(address _userAddress, uint investmentId) external view returns (uint) {
        require(users[_userAddress].wallet == _userAddress);
        User memory user = users[_userAddress];

        return _calcRewards(user.investments[investmentId]).sub(user.investments[investmentId].withdrawn);
    }

    function withdraw(uint investmentId) external {
        User storage user = users[msg.sender];
        Investment storage investment = user.investments[investmentId];
        require(user.wallet == msg.sender && investment.active); // investment should be active

        require(investment.lastWithdrawalAt + 1 days < block.timestamp); // we only allow one withdrawal each day

        uint availableAmount = _calcRewards(investment).sub(investment.withdrawn).sub(investment.penalty);

        require(availableAmount > 0);

        uint penalty = _calcPenalty(investment, availableAmount);

        if (penalty == 0) {
            availableAmount = availableAmount.sub(_calcPercentage(investment.deposit, holdBonusUnlocksAt)); // Only allow withdrawal if available is more then 10% of base

            uint maxAllowedWithdrawal = _calcPercentage(investment.deposit, maxWithdrawalOverTenPercent);

            if (availableAmount > maxAllowedWithdrawal) {
                availableAmount = maxAllowedWithdrawal;
            }
        }

        if (isInInsuranceState) {
            availableAmount = getInsuredAvailableAmount(investment, availableAmount);
        }

        availableAmount = availableAmount.sub(penalty);

        fourRXToken.transfer(user.wallet, availableAmount);

        investment.withdrawn = investment.withdrawn.add(availableAmount);
        investment.lastWithdrawalAt = block.timestamp;
        investment.holdFrom = block.timestamp;

        investment.penalty = investment.penalty.add(penalty);

        totalPenalty = totalPenalty.add(penalty);

        if (investment.withdrawn >= _calcPercentage(investment.deposit, maxContractRewards)) {
            investment.active = false; // if investment has withdrawn equals to or more then the max amount, then mark investment in-active
            totalActiveInvestments = totalActiveInvestments.sub(1);
        }

        checkForBaseInsuranceTrigger();

        totalWithdrawn = totalWithdrawn.add(availableAmount);

        emit Withdraw(user.wallet, availableAmount);
    }

    function exitProgram(uint investmentId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender);
        Investment storage investment = user.investments[investmentId];
        uint availableAmount = investment.deposit;
        uint penaltyAmount = _calcPercentage(investment.deposit, exitPenalty);

        availableAmount = availableAmount.sub(penaltyAmount);

        uint withdrawn = investment.withdrawn.add(investment.penalty);
        require(withdrawn <= availableAmount);
        availableAmount = availableAmount.sub(withdrawn); // @todo: discuss this new implementation with Assaf

        fourRXToken.transfer(user.wallet, availableAmount);

        investment.active = false;
        investment.withdrawn = investment.withdrawn.add(availableAmount);
        investment.penalty = investment.penalty.add(penaltyAmount);

        totalActiveInvestments = totalActiveInvestments.sub(1);
        totalExited = totalExited.add(1);

        totalWithdrawn = totalWithdrawn.add(availableAmount);
        totalPenalty = totalPenalty.add(penaltyAmount);

        emit Exited(user.wallet);
    }

    function insureInvestment(uint investmentId) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender);
        Investment storage investment = user.investments[investmentId];
        _insureInvestment(investment);
    }

    function getUser(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }

    function getPoolInfo() external view returns (uint, uint, uint, uint, PoolUser[10] memory, PoolUser[12] memory) {
        return (poolDrewAt, poolCycle, sponsorPoolBalance, refPoolBalance, sponsorPoolUsers, refPoolUsers);
    }

    function getContractInfo() external view returns (uint, uint, uint, uint, uint, uint, uint, uint, uint, uint, uint) {
        return (maxContractBalance, totalDeposits, totalWithdrawn, totalInvestments, totalActiveInvestments, totalRefRewards, totalRefPoolRewards, totalSponsorPoolRewards, totalDepositRewards, totalPenalty, totalExited);
    }
}
