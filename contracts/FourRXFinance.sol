// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract FourRXFinance {
    using SafeMath for uint;

    IERC20 fourRXToken;
    uint percentMultiplier = 10000;
    uint lpCommission = 1000;
    uint refCommission = 1000;

    uint poolCycle;
    uint poolDrewAt;

    uint refPoolBalance;
    uint sponsorPoolBalance;

    address[] refPoolUsers;
    address[] sponsorPoolUsers;

    struct RefPool {
        uint cycle;
        uint amount;
    }

    struct SponsorPool {
        uint cycle;
        uint amount;
    }

    struct User {
        address wallet;
        bool registered;
        bool active;
        uint deposit;
        address uplink;
        uint refCommission;
        uint refPoolRewards;
        uint sponsorPoolRewards;
        RefPool refPool;
        SponsorPool sponsorPool;
    }

    mapping (address => User) users;

    uint[] public refPoolBonuses;
    uint[] public sponsorPoolBonuses;

    uint[] public depositBonuses;

    constructor(IERC20 fourRXTokenAddress) {
        fourRXToken = fourRXTokenAddress;

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

    function _updateUserSponsorPool(uint amount, User storage user) internal {
        if (user.sponsorPool.cycle != poolCycle) {
            user.sponsorPool.cycle = poolCycle;
            user.sponsorPool.amount = 0;
        }

        user.sponsorPool.amount = user.sponsorPool.amount.add(amount);
    }

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
            uint commission = uplinkUser.refCommission.add(amount.mul(refCommission).div(percentMultiplier));
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

        return amount.mul(rewardPercent).div(percentMultiplier);
    }

    function drawPool() internal {
        if (block.timestamp > poolDrewAt + 1 days) {
            poolDrewAt = block.timestamp;
            for (uint i = 0; i < refPoolUsers.length; i++) {
                if (refPoolUsers[i] == address(0)) break;

                User storage user = users[refPoolUsers[i]];
                user.refPoolRewards = user.refPoolRewards.add(refPoolBalance.mul(refPoolBonuses[i]).div(percentMultiplier));
            }

            for (uint i = 0; i < sponsorPoolUsers.length; i++) {
                if (sponsorPoolUsers[i] == address(0)) break;

                User storage user = users[sponsorPoolUsers[i]];
                user.sponsorPoolRewards = user.sponsorPoolRewards.add(sponsorPoolBalance.mul(sponsorPoolBonuses[i]).div(percentMultiplier));
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
        user.deposit = amount.sub(amount.mul(lpCommission).div(percentMultiplier)).add(_calcDepositRewards(amount)); // Deduct LP Commission + add deposit rewards
        _updateUserSponsorPool(amount, user);
        _updateSponsorPoolUsers(user);

        _distributeReferralReward(amount, user.uplink);

        refPoolBalance = refPoolBalance.add(amount.mul(50).div(percentMultiplier));
        sponsorPoolBalance = sponsorPoolBalance.add(amount.mul(50).div(percentMultiplier));

        drawPool();
    }

//    function withdraw(uint amount) external {
//
//    }
}
