// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Pools.sol";


contract RewardsAndPenalties is Pools {
    using SafeMath for uint;

    function _distributeReferralReward(uint amount, Stake memory stake) internal {
        if (
            stake.uplink.uplinkAddress != address(0) &&
            users[stake.uplink.uplinkAddress].stakes[stake.uplink.uplinkInvestmentId].active
        ) {
            User storage uplinkUser = users[stake.uplink.uplinkAddress];

            uint commission = _calcPercentage(amount, REF_COMMISSION_BP);

            uplinkUser.stakes[stake.uplink.uplinkInvestmentId].refCommission = uplinkUser.stakes[stake.uplink.uplinkInvestmentId].refCommission.add(commission);

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

        uint interest = _calcPercentage(stake.deposit, getInterestTillDays(_calcDays(stake.interestCountFrom, block.timestamp)));

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
        // If user's rewards are more then 3% -- No penalty
        if (basisPoints >= REWARD_THRESHOLD_BP) {
            return 0;
        }

        return _calcPercentage(withdrawalAmount, PERCENT_MULTIPLIER.sub(basisPoints.mul(PERCENT_MULTIPLIER).div(REWARD_THRESHOLD_BP)));
    }
}
