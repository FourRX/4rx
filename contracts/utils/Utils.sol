// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract Utils {
    using SafeMath for uint;

    uint day = 86400; // Seconds in a day

    function _calcDays(uint start, uint end) public view returns (uint) {
        require(end >= start);

        return end.sub(start).div(day);
    }
}