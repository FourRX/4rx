// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "./InterestCalculator.sol";
import "./Events.sol";
import "./SafePercentageCalculator.sol";
import "./utils/Utils.sol";

contract SharedVariables is SafePercentageCalculator, InterestCalculator, Events, Utils {
    using SafeMath for uint;

    IERC20 fourRXToken;
    uint maxContractRewards = 40000; // 400%
    uint lpCommission = 1000;
    uint refCommission = 800;
    uint logBase = 1009;
    uint depositRefPoolCommission = 50;
    uint depositSponsorPoolCommission = 50;

    // Contract bonus
    uint maxContractBonus = 300; // maximum bonus a user can get 3%
    uint contractBonusUnit = 100;    // For each 100 unit balance of contract, gives
    uint contractBonusUnitBonus = 1; // 0.01% extra interest

    uint holdBonusUnitBonus = 2; // 0.02% hold bonus for each 12 hours of hold
    uint maxHoldBonus = 100; // Maximum 1% hold bonus
    uint holdBonusUnlocksAt = 1000; // User will only get hold bonus if his rewards are more then 10% of his deposit

    uint maxWithdrawalOverTenPercent = 300; // Max daily withdrawal limit if user is above 10%

    uint maxContractBalance;

    uint insuranceTrigger = 3500; // trigger insurance with contract balance fall below 35%

    bool isInInsuranceState = false; // if contract is only allowing insured money this becomes true;

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
        uint lastWithdrawalAt; // date time of last withdrawals so we don't allow more then 3% a day
        RefPool refPool; // To store this user's last 24 hour RefPool entries
        SponsorPool sponsorPool; // To store this user's last 24 hour Sponsor Pool entries
        uint withdrawn;
    }

    mapping (address => User) users;

    uint[] public refPoolBonuses;
    uint[] public sponsorPoolBonuses;

    uint[] public depositBonuses;
}
