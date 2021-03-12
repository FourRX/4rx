// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Pools.sol";


contract RewardsAndPenalties is Pools {
    using SafeMath for uint;

    function _distributeReferralReward(uint amount, Stake memory stake) internal {
        if (
            stake.uplink.uplinkAddress != address(0) &&
            users[stake.uplink.uplinkAddress].stakes[stake.uplink.uplinkStakeId].active
        ) {
            User storage uplinkUser = users[stake.uplink.uplinkAddress];

            uint commission = _calcPercentage(amount, REF_COMMISSION_BP);

            uplinkUser.stakes[stake.uplink.uplinkStakeId].refCommission = uplinkUser.stakes[stake.uplink.uplinkStakeId].refCommission.add(commission);

            if (stake.refPool.cycle != poolCycle) {
                stake.refPool.cycle = poolCycle;
                stake.refPool.amount = 0;
            }

            stake.refPool.amount = stake.refPool.amount.add(amount);

            _updateRefPoolUsers(uplinkUser, stake);

            totalRefRewards = totalRefRewards.add(commission);
        }
    }

    function _calcDepositRewards(uint amount) internal pure returns (uint) {
        uint rewardPercent = 0;

        if (amount > 175) {
            rewardPercent = 50; // 0.5%
        } else if (amount > 150) {
            rewardPercent = 40; // 0.4%
        } else if (amount > 135) {
            rewardPercent = 35; // 0.35%
        } else if (amount > 119) {
            rewardPercent = 30; // 0.3%
        } else if (amount > 100) {
            rewardPercent = 25; // 0.25%
        } else if (amount > 89) {
            rewardPercent = 20; // 0.2%
        } else if (amount > 75) {
            rewardPercent = 15; // 0.15%
        } else if (amount > 59) {
            rewardPercent = 10; // 0.1%
        } else if (amount > 45) {
            rewardPercent = 5; // 0.05%
        } else if (amount > 20) {
            rewardPercent = 2; // 0.02%
        } else if (amount > 9) {
            rewardPercent = 1; // 0.01%
        }

        return _calcPercentage(amount, rewardPercent);
    }

    function _calcContractBonus(Stake memory stake) internal view returns (uint) {
        uint contractBonusPercent = fourRXToken.balanceOf(address(this)).mul(CONTRACT_BONUS_PER_UNIT_BP).div(CONTRACT_BONUS_UNIT);

        if (contractBonusPercent > MAX_CONTRACT_BONUS_BP) {
            contractBonusPercent = MAX_CONTRACT_BONUS_BP;
        }

        return _calcPercentage(stake.deposit, contractBonusPercent);
    }

    function _calcHoldRewards(Stake memory stake) internal view returns (uint) {
        uint holdPeriods = _calcDays(stake.holdFrom, block.timestamp).mul(DAY).div(HOLD_BONUS_UNIT);
        uint holdBonusPercent = holdPeriods.mul(HOLD_BONUS_PER_UNIT_BP);

        if (holdBonusPercent > MAX_HOLD_BONUS_BP) {
            holdBonusPercent = MAX_HOLD_BONUS_BP;
        }

        return _calcPercentage(stake.deposit, holdBonusPercent);
    }

    function _calcRewardsWithoutHoldBonus(Stake memory stake) internal view returns (uint) {
        uint poolRewardsAmount = stake.refPoolRewards.add(stake.sponsorPoolRewards);
        uint refCommissionAmount = stake.refCommission;

        uint interest = _calcPercentage(stake.deposit, _getInterestTillDays(_calcDays(stake.interestCountFrom, block.timestamp)));

        uint contractBonus = _calcContractBonus(stake);

        uint totalRewardsWithoutHoldBonus = poolRewardsAmount.add(refCommissionAmount).add(interest).add(contractBonus);

        return totalRewardsWithoutHoldBonus;
    }

    function _calcRewards(Stake memory stake) internal view returns (uint) {
        uint rewards = _calcRewardsWithoutHoldBonus(stake);

        if (_calcBasisPoints(stake.deposit, rewards) >= REWARD_THRESHOLD_BP) {
            rewards = rewards.add(_calcHoldRewards(stake));
        }

        uint maxRewards = _calcPercentage(stake.deposit, MAX_CONTRACT_REWARD_BP);

        if (rewards > maxRewards) {
            rewards = maxRewards;
        }

        return rewards;
    }

    function _calcPenalty(Stake memory stake, uint withdrawalAmount) internal pure returns (uint) {
        uint basisPoints = _calcBasisPoints(stake.deposit, withdrawalAmount);
        // If user's rewards are more then REWARD_THRESHOLD_BP -- No penalty
        if (basisPoints >= REWARD_THRESHOLD_BP) {
            return 0;
        }

        return _calcPercentage(withdrawalAmount, PERCENT_MULTIPLIER.sub(basisPoints.mul(PERCENT_MULTIPLIER).div(REWARD_THRESHOLD_BP)));
    }
}
