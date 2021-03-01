// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Pools.sol";

contract RewardsAndPenalties is Pools {

    function _distributeReferralReward(uint amount, Investment memory investment) internal {
        if (investment.uplink.uplinkAddress != address(0) && users[investment.uplink.uplinkAddress].investments[investment.uplink.uplinkInvestmentId].active) {
            User storage uplinkUser = users[investment.uplink.uplinkAddress];

            uint commission = _calcPercentage(amount, refCommission);

            uplinkUser.investments[investment.uplink.uplinkInvestmentId].refCommission = uplinkUser.investments[investment.uplink.uplinkInvestmentId].refCommission.add(commission);

            _updateInvestmentRefPool(commission, uplinkUser.investments[investment.uplink.uplinkInvestmentId]);
            _updateRefPoolUsers(uplinkUser, investment);
        }
    }

    function _calcDepositRewards(uint amount) internal view returns (uint) {
        uint rewardPercent = 0;

        if (amount > 5000000) {
            rewardPercent = 50;
        } else if (amount > 1000000) {
            rewardPercent = 40;
        } else if (amount > 800000) {
            rewardPercent = 35;
        } else if (amount > 500000) {
            rewardPercent = 30;
        } else if (amount > 250000) {
            rewardPercent = 25;
        } else if (amount > 100000) {
            rewardPercent = 20;
        } else if (amount > 50000) {
            rewardPercent = 15;
        } else if (amount > 25000) {
            rewardPercent = 10;
        } else if (amount > 10000) {
            rewardPercent = 5;
        } else if (amount > 5000) {
            rewardPercent = 2;
        } else if (amount > 2000) {
            rewardPercent = 1;
        }

        return _calcPercentage(amount, rewardPercent);
    }

    function _calcContractBonus(User memory user) internal view returns (uint) {
        uint contractBonusPercent = fourRXToken.balanceOf(address(this)).div(contractBonusUnit).mul(contractBonusUnitBonus);

        if (contractBonusPercent > maxContractBonus) {
            contractBonusPercent = maxContractBonus;
        }

        return _calcPercentage(user.deposit, contractBonusPercent);
    }

    function _calcHoldRewards(User memory user) internal view returns (uint) {
        uint holdPeriods = _calcDays(user.holdFrom, block.timestamp).mul(2);
        uint holdBonusPercent = holdPeriods.mul(holdBonusUnitBonus);

        if (holdBonusPercent > maxHoldBonus) {
            holdBonusPercent = maxHoldBonus;
        }

        return _calcPercentage(user.deposit, holdBonusPercent);
    }

    function _calcRewardsWithoutHoldBonus(User memory user) internal view returns (uint) {
        uint poolRewardsAmount = user.refPoolRewards.add(user.sponsorPoolRewards);
        uint refCommissionAmount = user.refCommission;

        uint interest = _calcPercentage(user.deposit, getInterestTillDays(_calcDays(user.interestCountFrom, block.timestamp)));

        uint contractBonus = _calcContractBonus(user);

        uint totalRewardsWithoutHoldBonus = poolRewardsAmount.add(refCommissionAmount).add(interest).add(contractBonus);

        return totalRewardsWithoutHoldBonus;
    }

    function _calcRewards(User memory user) internal view returns (uint) {
        uint rewards = _calcRewardsWithoutHoldBonus(user);

        if (_calcBasisPoints(user.deposit, rewards) >= holdBonusUnlocksAt) {
            rewards = rewards.add(_calcHoldRewards(user));
        }

        uint maxRewards = _calcPercentage(user.deposit, maxContractRewards);

        if (rewards > maxRewards) {
            rewards = maxRewards;
        }

        return rewards;
    }

    function _calcPenalty(User memory user, uint withdrawalAmount) internal view returns (uint) {
        uint basisPoints = _calcBasisPoints(user.deposit, withdrawalAmount);
        // If user's rewards are more then 3% -- No penalty
        if (basisPoints >= holdBonusUnlocksAt) {
            return 0;
        }
        // If user's rewards are less then then 2% -- 66% penalty
        if (basisPoints < 200) {
            return _calcPercentage(withdrawalAmount, 6600);
        }

        // If user's rewards are less then then 3% and greater or equals to 2% -- 33% penalty
        return _calcPercentage(withdrawalAmount, 3300);
    }
}
