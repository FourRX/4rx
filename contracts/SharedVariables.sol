// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./InterestCalculator.sol";
import "./Events.sol";
import "./PercentageCalculator.sol";
import "./utils/Utils.sol";
import "./Constants.sol";
import "./StatsVars.sol";


contract SharedVariables is Constants, StatsVars, PercentageCalculator, InterestCalculator, Events, Utils {
    using SafeMath for uint;

    IERC20 public fourRXToken;

    address public devAddress = 0x64B8cb4C04Ba902010856d913B4e5DF940748Bf2; // Dummy address replace it for prod/dev

    struct PoolUser {
        address user; // user's address
        uint8 stakeId;
    }

    struct Pool {
        uint16 cycle;
        uint amount;
    }

    struct Stake {
        uint8 id;
        bool active;
        bool optInInsured; // Is insured ???

        uint deposit; // Initial Deposit
        uint withdrawn; // Total withdrawn from this stake
        uint penalty; // Total penalty on this stale

        // Rewards
        uint refCommission; // Ref rewards
        uint refPoolRewards; // Ref Pool Rewards
        uint sponsorPoolRewards; // Sponsor Pool Rewards

        uint32 holdFrom; // Timestamp from which hold should be counted
        uint32 interestCountFrom; // TimeStamp from which interest should be counted, from the beginning
        uint32 lastWithdrawalAt; // date time of last withdrawals so we don't allow more then 3% a day

        Pool refPool; // To store this user's last 24 hour RefPool entries
        Pool sponsorPool; // To store this user's last 24 hour Sponsor Pool entries
    }

    struct User {
        address wallet; // Wallet Address
        Stake[] stakes;
    }

    mapping (address => User) public users;

    PoolUser[12] public refPoolUsers;
    PoolUser[10] public sponsorPoolUsers;

    uint[] public refPoolBonuses;
    uint[] public sponsorPoolBonuses;

    uint public maxContractBalance;

    uint16 public poolCycle;
    uint32 public poolDrewAt;

    uint public refPoolBalance;
    uint public sponsorPoolBalance;
}
