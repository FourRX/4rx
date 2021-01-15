// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Pools.sol";

contract RewardsAndPenalties is Pools {

    function _distributeReferralReward(uint amount, address uplink) internal {
        if (uplink != address(0)) {
            User storage uplinkUser = users[uplink];
            uint commission = uplinkUser.refCommission.add(_calcPercentage(amount, refCommission));
            uplinkUser.refCommission = commission;
            _updateUserRefPool(commission, uplinkUser);
            _updateRefPoolUsers(uplinkUser);
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
        if (basisPoints >= holdBonusUnlocksAt) {
            return 0;
        }

        return percentMultiplier.sub(basisPoints.mul(percentMultiplier).div(holdBonusUnlocksAt));
    }
}
