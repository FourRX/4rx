// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract SafePercentageCalculator {
    using SafeMath for uint;

    uint private percentMultiplier = 10000;
    uint private minBasisPoints = 0;
    uint private maxBasisPoints = 200000;

    function _calcPercentage(uint amount, uint basisPoints) internal view returns (uint) {
        require(basisPoints >= minBasisPoints);
        require(basisPoints <= maxBasisPoints);
        return amount.mul(basisPoints).div(percentMultiplier);
    }

    function _calcBasisPoints(uint base, uint interest) internal view returns (uint) {
        return interest.mul(percentMultiplier).div(base);
    }
}
