// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/SortedLinkedList.sol";


contract ReferralPool {
    using SafeMath for uint;

    SortedLinkedList.Item[] public refPoolUsers;

    function _addRefPoolRecord(address user, uint amount, uint8 stakeId, uint16 prev, uint16 newPrev, uint16 current) public {
        if (newPrev == SortedLinkedList.GUARD) {
            SortedLinkedList.addNode(refPoolUsers, user, amount, stakeId, prev);
        } else {
            require(current != SortedLinkedList.GUARD);
            SortedLinkedList.updateNode(refPoolUsers, user, amount.add(refPoolUsers[current].score), stakeId, current, prev, newPrev);
        }
    }

    function _cleanRefPoolUsers() public {
        delete refPoolUsers;
        SortedLinkedList.initNodes(refPoolUsers);
    }
}
