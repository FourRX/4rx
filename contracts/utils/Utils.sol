pragma solidity ^0.4.0;

import '@openzeppelin/contracts/math/SafeMath.sol';

contract Utils {
    using SafeMath for uint;

    uint day = 86400; // Seconds in a day

    function _calcDays(uint start, uint end) private pure returns(uint) {
        require(end >= start);

        return end.sub(start).div(day);
    }
}
