// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./RewardsAndPenalties.sol";

contract Insurance is RewardsAndPenalties {
    uint baseInsuranceForBP = 3500; // trigger insurance with contract balance fall below 35%


    bool isInInsuranceState = false; // if contract is only allowing insured money this becomes true;

    uint optInInsuranceFeeBP = 1000; // 10%
    uint optInInsuranceForBP = 10000; // 100%

    function checkForBaseInsuranceTrigger() internal {
        if (fourRXToken.balanceOf(address(this)) <= _calcPercentage(maxContractBalance, baseInsuranceForBP)) {
            isInInsuranceState = true;
        } else {
            isInInsuranceState = false;
        }
    }

    function getInsuredAvailableAmount(Investment memory investment, uint availableAmount) internal view returns (uint)
    {
        // Calc correct insured value by checking which insurance should be applied
        uint insuredFor = baseInsuranceForBP;
        if (investment.optInInsured) {
            insuredFor = optInInsuranceForBP;
        }

        uint maxWithdrawalAllowed = _calcPercentage(investment.deposit, insuredFor);
        require(maxWithdrawalAllowed < investment.withdrawn); // if contract is in insurance trigger, do not allow withdrawals for the users who already have withdrawn more then 35%

        if (investment.withdrawn.add(availableAmount) > maxWithdrawalAllowed) {
            availableAmount = maxWithdrawalAllowed - investment.withdrawn;
        }

        return availableAmount;
    }

    function _insureInvestment(Investment storage investment) internal {
        require(!investment.optInInsured && investment.active);

        investment.deposit = investment.deposit.sub(_calcPercentage(investment.deposit, optInInsuranceFeeBP));
        investment.optInInsured = true;
    }


}
