// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./InterestCalculator.sol";
import "./Events.sol";
import "./SafePercentageCalculator.sol";
import "./utils/Utils.sol";

contract SharedVariables is SafePercentageCalculator, InterestCalculator, Events, Utils {
    using SafeMath for uint;

    IERC20 public fourRXToken;
    uint public maxContractRewards = 30000; // 300%
    uint public lpCommission = 1000;
    uint public refCommission = 700;

    uint public devCommission = 5000; // 5%
    address public devAddress = 0x64B8cb4C04Ba902010856d913B4e5DF940748Bf2; // Dummy address replace it for prod/dev

    uint public depositRefPoolCommission = 50;
    uint public depositSponsorPoolCommission = 50;
    uint public exitPenalty = 5000;

    // Contract bonus
    uint public maxContractBonus = 300; // maximum bonus a user can get 3%
    uint public contractBonusUnit = 100;    // For each 100 unit balance of contract, gives
    uint public contractBonusUnitBonus = 1; // 0.01% extra interest

    uint public holdBonusUnitBonus = 2; // 0.02% hold bonus for each 12 hours of hold
    uint public maxHoldBonus = 100; // Maximum 1% hold bonus
    uint public holdBonusUnlocksAt = 300; // User will only get hold bonus if his rewards are more then 10% of his deposit

    uint public maxWithdrawalOverTenPercent = 300; // Max daily withdrawal limit if user is above 10%

    uint public maxContractBalance;

    uint public poolCycle;
    uint public poolDrewAt;

    uint public refPoolBalance;
    uint public sponsorPoolBalance;

    struct PoolUser {
        address user;
        uint investmentId;
    }

    PoolUser[12] public refPoolUsers;
    PoolUser[10] public sponsorPoolUsers;

    struct RefPool {
        uint cycle;
        uint amount;
    }

    struct SponsorPool {
        uint cycle;
        uint amount;
    }

    struct Uplink {
        address uplinkAddress;
        uint uplinkInvestmentId;
    }

    struct Investment {
        uint id;
        bool active;
        uint interestCountFrom; // TimeStamp from which interest should be counted
        uint holdFrom; // Timestamp from which hold should be counted
        uint deposit; // Initial Deposit
        Uplink uplink; // Referrer
        uint refCommission; // Ref rewards
        uint refPoolRewards; // Ref Pool Rewards
        uint sponsorPoolRewards; // Sponsor Pool Rewards
        uint lastWithdrawalAt; // date time of last withdrawals so we don't allow more then 3% a day
        RefPool refPool; // To store this user's last 24 hour RefPool entries
        SponsorPool sponsorPool; // To store this user's last 24 hour Sponsor Pool entries
        uint withdrawn;
        bool optInInsured; // Is insured ???
        uint penalty;
    }

    struct User {
        address wallet; // Wallet Address
        bool registered;
        Investment[] investments;
    }

    mapping (address => User) public users;

    uint[] public refPoolBonuses;
    uint[] public sponsorPoolBonuses;

    uint[] public depositBonuses;

    // Stats
    uint public totalDeposits;
    uint public totalWithdrawn;
    uint public totalInvestments;
    uint public totalActiveInvestments;
    uint public totalRefRewards;
    uint public totalRefPoolRewards;
    uint public totalSponsorPoolRewards;
    uint public totalDepositRewards;
    uint public totalPenalty;
    uint public totalExited;
}
