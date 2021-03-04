// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SharedVariables.sol";

contract Pools is SharedVariables {

    function _resetPools() internal {
        for (uint i = 0; i < refPoolBonuses.length; i++) {
            refPoolUsers[i].user = address(0);
            refPoolUsers[i].investmentId = 0;
        }

        for (uint i = 0; i < sponsorPoolBonuses.length; i++) {
            sponsorPoolUsers[i].user = address(0);
            refPoolUsers[i].investmentId = 0;
        }

        refPoolBalance = 0;
        sponsorPoolBalance = 0;
        poolDrewAt = block.timestamp;
    }

    function _updateSponsorPoolUsers(User memory user, Investment memory investment) internal {
        if (sponsorPoolUsers[sponsorPoolUsers.length.sub(1)].user == address(0)
            || investment.sponsorPool.amount > users[sponsorPoolUsers[sponsorPoolUsers.length.sub(1)].user].investments[sponsorPoolUsers[sponsorPoolUsers.length.sub(1)].investmentId].sponsorPool.amount) { // either last user is not set or last user's sponsor balance is less then this user

            PoolUser memory shiftUser;

            for (uint i = 0; i < sponsorPoolUsers.length; i++) {

                if (sponsorPoolUsers[i].user == address(0)) {
                    sponsorPoolUsers[i].user = user.wallet;
                    sponsorPoolUsers[i].investmentId = investment.id;
                    break;
                }

                if (investment.sponsorPool.amount > users[sponsorPoolUsers[i].user].investments[sponsorPoolUsers[i].investmentId].sponsorPool.amount) {
                    shiftUser = sponsorPoolUsers[i];
                    sponsorPoolUsers[i].user = user.wallet;
                    sponsorPoolUsers[i].investmentId = investment.id;
                    PoolUser memory nextUser;
                    for (uint j = i; i < sponsorPoolUsers.length; j++) {

                        if (shiftUser.user == address(0)) {
                            break;
                        }

                        nextUser = sponsorPoolUsers[j];
                        sponsorPoolUsers[j] = shiftUser;
                        shiftUser = nextUser;
                    }
//                    _shiftPool(i, shiftUser, sponsorPoolUsers);
                    break;
                }
            }
        }
    }

    // Reorganise top ref-pool users to draw pool for
    function _updateRefPoolUsers(User memory user, Investment memory investment) internal {
        if (refPoolUsers[refPoolUsers.length - 1].user == address(0)
            || investment.refPool.amount > users[refPoolUsers[refPoolUsers.length - 1].user].investments[refPoolUsers[refPoolUsers.length - 1].investmentId].refPool.amount) { // either last user is not set or last user's ref balance is less then this user

            PoolUser memory shiftUser;

            for (uint i = 0; i < refPoolUsers.length; i++) {

                if (refPoolUsers[i].user == address(0)) {
                    refPoolUsers[i].user = user.wallet;
                    refPoolUsers[i].investmentId = investment.id;
                    break;
                }

                if (investment.refPool.amount > users[refPoolUsers[i].user].investments[refPoolUsers[i].investmentId].refPool.amount) {
                    shiftUser = refPoolUsers[i];
                    refPoolUsers[i].user = user.wallet;
                    refPoolUsers[i].investmentId = investment.id;
                    PoolUser memory nextUser;
                    for (uint j = i; i < refPoolUsers.length; j++) {

                        if (shiftUser.user == address(0)) {
                            break;
                        }

                        nextUser = refPoolUsers[j];
                        refPoolUsers[j] = shiftUser;
                        shiftUser = nextUser;
                    }
//                    _shiftPool(i, shiftUser, refPoolUsers);
                    break;
                }
            }
        }
    }

    function drawPool() internal {
        if (block.timestamp > poolDrewAt + 1 days) {
            for (uint i = 0; i < refPoolUsers.length; i++) {
                if (refPoolUsers[i].user == address(0)) break;

                User storage user = users[refPoolUsers[i].user];
                user.investments[refPoolUsers[i].investmentId].refPoolRewards = user.investments[refPoolUsers[i].investmentId].refPoolRewards.add(_calcPercentage(refPoolBalance, refPoolBonuses[i]));
            }

            for (uint i = 0; i < sponsorPoolUsers.length; i++) {
                if (sponsorPoolUsers[i].user == address(0)) break;

                User storage user = users[sponsorPoolUsers[i].user];
                user.investments[sponsorPoolUsers[i].investmentId].sponsorPoolRewards = user.investments[sponsorPoolUsers[i].investmentId].sponsorPoolRewards.add(_calcPercentage(sponsorPoolBalance, sponsorPoolBonuses[i]));
            }

            _resetPools();
        }
    }
}
