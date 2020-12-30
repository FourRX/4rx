// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

contract FourRXFinance {
    using SafeMath for uint;

    IERC20 fourRXToken;
    uint percentMultiplier = 10000;
    uint lpCommission = 1000;

    struct User {
        bool registered;
        bool active;
        uint deposit;
        address uplink;
        uint refCommission;
    }

    mapping (address => User) public users;

    uint[] public refCommissions;

    uint[] public refPoolBonuses;
    uint[] public sponsorPoolBonuses;

    uint[] public depositBonuses;

    constructor(IERC20 fourRXTokenAddress) {
        fourRXToken = fourRXTokenAddress;

        refCommissions.push(300);
        refCommissions.push(250);
        refCommissions.push(200);
        refCommissions.push(100);
        refCommissions.push(50);

        refPoolBonuses.push(2200); // @todo: fix this sum
        refPoolBonuses.push(1900);
        refPoolBonuses.push(1500);
        refPoolBonuses.push(1200);
        refPoolBonuses.push(1000);
        refPoolBonuses.push(800);
        refPoolBonuses.push(700);
        refPoolBonuses.push(600);
        refPoolBonuses.push(500);
        refPoolBonuses.push(300);
        refPoolBonuses.push(200);
        refPoolBonuses.push(100);
        refPoolBonuses.push(75);
        refPoolBonuses.push(25);

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
    }

    function _distributeReferralReward(uint amount, address uplink) internal {
        for (uint i = 0; i < refCommissions.length; i++) {
            if (uplink == address(0)) break;

            User storage uplinkUser = users[uplink];
            uplinkUser.refCommission = uplinkUser.refCommission.add(amount.mul(refCommissions[i]).div(percentMultiplier));
            uplink = uplinkUser.uplink;
            // @todo: check for referral pool top 10 here
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

    function deposit(uint amount, address uplink) external {
        require(!users[msg.sender].registered); // User must not be registered with us
        require(users[uplink].active || uplink == address(0)); // Either uplink must be registered with us and be a active user or 0 address

        // @todo: call transferFrom right here

        User storage user = users[msg.sender];

        user.registered = true;
        user.active = true;
        user.uplink = uplink;
        user.deposit = amount.sub(amount.mul(lpCommission).div(percentMultiplier)).add(_calcDepositRewards(amount)); // Deduct LP Commission + add deposit rewards
        // @todo: check for sponsorPoolBonuses here

        _distributeReferralReward(amount, user.uplink);
    }

//    function withdraw(uint amount) external {
//
//    }
}
