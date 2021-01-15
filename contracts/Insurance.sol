// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./RewardsAndPenalties.sol";

contract Insurance is RewardsAndPenalties {
    function checkForInsuranceTrigger() internal {
        if (fourRXToken.balanceOf(address(this)) <= _calcPercentage(maxContractBalance, insuranceTrigger)) {
            isInInsuranceState = true;
        } else {
            isInInsuranceState = false;
        }
    }
}
