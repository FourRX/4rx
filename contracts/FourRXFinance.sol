// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import "./InterestCalculator.sol";
import "./SafePercentageCalculator.sol";
import "./utils/Utils.sol";

contract FourRXFinance is SafePercentageCalculator, InterestCalculator, Utils {
    using SafeMath for uint;

    IERC20 fourRXToken;
    uint maxContractRewards = 40000; // 400%
    uint lpCommission = 1000;
    uint refCommission = 1000;
    uint logBase = 1009;
    uint depositRefPoolCommission = 50;
    uint depositSponsorPoolCommission = 50;

    // Contract bonus
    uint maxContractBonus = 300; // maximum bonus a user can get 3%
    uint contractBonusUnit = 100; // For each 100 unit balance of contract, give
    uint contractBonusUnitBonus = 1; // 0.01% extra interest

    uint holdBonusUnitBonus = 2; // 0.02% hold bonus for each 12 hours of hold
    uint maxHoldBonus = 100; // Maximum 1% hold bonus
    uint holdBonusUnlocksAt = 1000; // User will only get hold bonus if his rewards are more then 10% of his deposit

    uint poolCycle;
    uint poolDrewAt;

    uint refPoolBalance;
    uint sponsorPoolBalance;

    address[] refPoolUsers = new address[](12);
    address[] sponsorPoolUsers = new address[](10);

    struct RefPool {
        uint cycle;
        uint amount;
    }

    struct SponsorPool {
        uint cycle;
        uint amount;
    }

    struct User {
        address wallet; // Wallet Address
        bool registered;
        bool active;
        uint interestCountFrom; // TimeStamp from which interest should be counted
        uint holdFrom; // Timestamp from which hold should be counted
        uint deposit; // Initial Deposit
        address uplink; // Referrer
        uint refCommission; // Ref rewards
        uint refPoolRewards; // Ref Pool Rewards
        uint sponsorPoolRewards; // Sponsor Pool Rewards
        RefPool refPool; // To store this user's last 24 hour RefPool entries
        SponsorPool sponsorPool; // To store this user's last 24 hour Sponsor Pool entries
        uint withdrawn;
    }

    mapping (address => User) users;

    uint[] public refPoolBonuses;
    uint[] public sponsorPoolBonuses;

    uint[] public depositBonuses;

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

    function _resetPools() internal {
        for (uint i = 0; i < refPoolBonuses.length; i++) {
            refPoolUsers[i] = address(0);
        }

        for (uint i = 0; i < sponsorPoolBonuses.length; i++) {
            sponsorPoolUsers[i] = address(0);
        }

        refPoolBalance = 0;
        sponsorPoolBalance = 0;
    }

    function _shiftPool(uint startIndex, address shiftAddress, address[] storage pool) internal {
        if (shiftAddress != address(0)) {
            address nextAddress = address(0);

            for (uint i = startIndex; i < pool.length; i++) {

                if (shiftAddress == address(0)) {
                    break;
                }

                nextAddress = pool[i];
                pool[i] = shiftAddress;
                shiftAddress = nextAddress;
            }
        }
    }

    function _updateSponsorPoolUsers(User memory user) internal {
        if (sponsorPoolUsers[sponsorPoolUsers.length - 1] == address(0)
            || user.sponsorPool.amount > users[sponsorPoolUsers[sponsorPoolUsers.length - 1]].sponsorPool.amount) { // either last user is not set or last user's sponsor balance is less then this user

            address shiftAddress = address(0);

            for (uint i = 0; i < sponsorPoolUsers.length; i++) {

                if (sponsorPoolUsers[i] == address(0)) {
                    sponsorPoolUsers[i] = user.wallet;
                    break;
                }

                if (user.sponsorPool.amount > users[sponsorPoolUsers[i]].sponsorPool.amount) {
                    shiftAddress = sponsorPoolUsers[i];
                    sponsorPoolUsers[i] = user.wallet;
                    _shiftPool(i, shiftAddress, sponsorPoolUsers);
                    break;
                }
            }
        }
    }

    // Update current user's sponsor pool entry
    function _updateUserSponsorPool(uint amount, User storage user) internal {
        if (user.sponsorPool.cycle != poolCycle) {
            user.sponsorPool.cycle = poolCycle;
            user.sponsorPool.amount = 0;
        }

        user.sponsorPool.amount = user.sponsorPool.amount.add(amount);
    }

    // Reorganise top ref-pool users to draw pool for
    function _updateRefPoolUsers(User memory user) internal {
        if (refPoolUsers[refPoolUsers.length - 1] == address(0)
            || user.refPool.amount > users[refPoolUsers[refPoolUsers.length - 1]].refPool.amount) { // either last user is not set or last user's ref balance is less then this user

            address shiftAddress = address(0);

            for (uint i = 0; i < refPoolUsers.length; i++) {

                if (refPoolUsers[i] == address(0)) {
                    refPoolUsers[i] = user.wallet;
                    break;
                }

                if (user.refPool.amount > users[refPoolUsers[i]].refPool.amount) {
                    shiftAddress = refPoolUsers[i];
                    refPoolUsers[i] = user.wallet;
                    _shiftPool(i, shiftAddress, refPoolUsers);
                    break;
                }
            }
        }
    }

    function _updateUserRefPool(uint amount, User storage user) internal {
        if (user.refPool.cycle != poolCycle) {
            user.refPool.cycle = poolCycle;
            user.refPool.amount = 0;
        }

        user.refPool.amount = user.refPool.amount.add(amount);
    }

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

    function drawPool() internal {
        if (block.timestamp > poolDrewAt + 1 days) {
            poolDrewAt = block.timestamp;
            for (uint i = 0; i < refPoolUsers.length; i++) {
                if (refPoolUsers[i] == address(0)) break;

                User storage user = users[refPoolUsers[i]];
                user.refPoolRewards = user.refPoolRewards.add(_calcPercentage(refPoolBalance, refPoolBonuses[i]));
            }

            for (uint i = 0; i < sponsorPoolUsers.length; i++) {
                if (sponsorPoolUsers[i] == address(0)) break;

                User storage user = users[sponsorPoolUsers[i]];
                user.sponsorPoolRewards = user.sponsorPoolRewards.add(_calcPercentage(sponsorPoolBalance, sponsorPoolBonuses[i]));
            }

            _resetPools();
        }
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

        uint contractBonus = _calcHoldRewards(user);

        uint totalRewardsWithoutHoldBonus = poolRewardsAmount.add(refCommissionAmount).add(interest).add(contractBonus);

        return totalRewardsWithoutHoldBonus;
    }

    function _calcRewards(User memory user) internal view returns (uint) {
        uint rewards = _calcRewardsWithoutHoldBonus(user);

        if (_calcBasisPoints(user.deposit.sub(user.withdrawn), rewards) >= holdBonusUnlocksAt) {
            rewards = rewards.add(_calcHoldRewards(user));
        }

        uint maxRewards = _calcPercentage(user.deposit, maxContractRewards);

        if (rewards > maxRewards) {
            rewards = maxRewards;
        }

        return rewards;
    }

    function balanceOf(address _userAddress) external view returns (uint) {
        require(users[_userAddress].wallet == _userAddress);
        User memory user = users[_userAddress];

        return _calcRewards(user).sub(user.withdrawn);
    }

    function withdraw(uint _amount) external {

    }

    function reInvest(uint _amount) external {

    }


//    function withdraw(uint amount) external {
//
//    }

}
