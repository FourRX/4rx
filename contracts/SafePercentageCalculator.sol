// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract SafePercentageCalculator {
    using SafeMath for uint;

    uint percentMultiplier = 10000;
    uint minBasisPoints = 0;
    uint maxBasisPoints = 40000; // 400% max

    function _calcPercentage(uint amount, uint basisPoints) public view returns (uint) {
        require(basisPoints >= minBasisPoints);
        require(basisPoints <= maxBasisPoints);
        return amount.mul(basisPoints).div(percentMultiplier);
    }

    function _calcBasisPoints(uint base, uint interest) public view returns (uint) {
        return interest.mul(percentMultiplier).div(base);
    }
}
