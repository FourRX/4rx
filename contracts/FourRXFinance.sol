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

    function deposit(uint amount, address uplink) external {
        require(!users[msg.sender].registered); // User must not be registered with us
        require(users[uplink].active || uplink == address(0)); // Either uplink must be registered with us and be a active user or 0 address

        require(fourRXToken.transferFrom(msg.sender, address(this), amount));

        User storage user = users[msg.sender];

        user.wallet = msg.sender;
        user.registered = true;
        user.active = true;
        user.uplink = uplink;
        user.interestCountFrom = block.timestamp;
        user.holdFrom = block.timestamp;
        user.deposit = amount.sub(_calcPercentage(amount, lpCommission)).add(_calcDepositRewards(amount)); // Deduct LP Commission + add deposit rewards
        _updateUserSponsorPool(amount, user);
        _updateSponsorPoolUsers(user);

        _distributeReferralReward(amount, user.uplink);

        refPoolBalance = refPoolBalance.add(_calcPercentage(amount, depositRefPoolCommission));
        sponsorPoolBalance = sponsorPoolBalance.add(_calcPercentage(amount, depositSponsorPoolCommission));

        drawPool();

        uint currentContractBalance = fourRXToken.balanceOf(address(this));

        if (currentContractBalance > maxContractBalance) {
            maxContractBalance = currentContractBalance;
        }

        emit Deposit(msg.sender, uplink, amount);
    }


    function balanceOf(address _userAddress) external view returns (uint) {
        require(users[_userAddress].wallet == _userAddress);
        User memory user = users[_userAddress];

        return _calcRewards(user).sub(user.withdrawn);
    }

    function withdraw() external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender);
        require(user.lastWithdrawalAt + 1 days < block.timestamp); // we only allow one withdrawal each day

        uint availableAmount = _calcRewards(user).sub(user.withdrawn);

        require(availableAmount > 0);

        uint penalty = _calcPenalty(user, availableAmount);

        if (penalty == 0) {
            availableAmount = availableAmount.sub(_calcPercentage(user.deposit, holdBonusUnlocksAt));

            uint maxAllowedWithdrawal = _calcPercentage(user.deposit, maxWithdrawalOverTenPercent);

            if (availableAmount > maxAllowedWithdrawal) {
                availableAmount = maxAllowedWithdrawal;
            }
        }

        if (isInInsuranceState) {
            uint maxWithdrawalAllowedInInsurance = _calcPercentage(user.deposit, insuranceTrigger);
            require(maxWithdrawalAllowedInInsurance < user.withdrawn); // if contract is in insurance trigger, do not allow withdrawals for the users who already have withdrawn more then 35%

            if (user.withdrawn.add(availableAmount) > maxWithdrawalAllowedInInsurance) {
                availableAmount = maxWithdrawalAllowedInInsurance - user.withdrawn;
            }
        }

        fourRXToken.transfer(user.wallet, availableAmount.sub(penalty));

        user.withdrawn = user.withdrawn.add(availableAmount);
        user.lastWithdrawalAt = block.timestamp;
        user.holdFrom = block.timestamp;

        checkForInsuranceTrigger();

        emit Withdraw(user.wallet, availableAmount);
    }

    function reInvest(uint _amount) external {
        User storage user = users[msg.sender];
        require(user.wallet == msg.sender);
        uint availableAmount = _calcRewards(user).sub(user.withdrawn);
        require(_amount <= availableAmount);

        uint newBase = user.deposit.add(_amount);

        uint availableAmountInInterest = _calcBasisPoints(newBase, availableAmount.sub(_amount));

        uint newDays = getEstimateDaysFromInterest(availableAmountInInterest);

        user.deposit = newBase;
        user.interestCountFrom = block.timestamp.sub(newDays.mul(day));
        user.holdFrom = block.timestamp;

        emit ReInvest(user.wallet, _amount);
    }

    function getUser(address userAddress) external view returns (User memory) {
        return users[userAddress];
    }
}
