// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "./InterestCalculator.sol";
import "./Events.sol";
import "./PercentageCalculator.sol";
import "./utils/Utils.sol";
import "./Constants.sol";

contract SharedVariables is Constants, Events, PercentageCalculator, InterestCalculator, Utils {

    uint public constant fourRXTokenDecimals = 8;
    IERC20 public fourRXToken;
    address public devAddress;

    struct Stake {
        uint8 id;
        bool active;
        bool optInInsured; // Is insured ???

        uint32 holdFrom; // Timestamp from which hold should be counted
        uint32 interestCountFrom; // TimeStamp from which interest should be counted, from the beginning
        uint32 lastWithdrawalAt; // date time of last withdrawals so we don't allow more then 3% a day

        uint origDeposit;
        uint deposit; // Initial Deposit
        uint withdrawn; // Total withdrawn from this stake
        uint penalty; // Total penalty on this stale

        uint rewards;
    }

    struct User {
        address wallet; // Wallet Address
        Stake[] stakes;
    }

    mapping (address => User) public users;

    uint public maxContractBalance;

    uint16 public poolCycle;
    uint32 public poolDrewAt;

    uint public refPoolBalance;
    uint public sponsorPoolBalance;

    uint public devBalance;

    uint[12] public refPoolBonuses;
    uint[10] public sponsorPoolBonuses;
}
