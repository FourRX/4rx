// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SharedVariables.sol";

contract Pools is SharedVariables {

    function _resetPools() internal {
        for (uint i = 0; i < refPoolBonuses.length; i++) {
            refPoolUsers[i] = address(0);
        }

        for (uint i = 0; i < sponsorPoolBonuses.length; i++) {
            sponsorPoolUsers[i] = address(0);
        }

        refPoolBalance = 0;
        sponsorPoolBalance = 0;
        poolDrewAt = block.timestamp;
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

    function drawPool() internal {
        if (block.timestamp > poolDrewAt + 1 days) {
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
}
