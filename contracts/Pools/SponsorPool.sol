// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../libs/SortedLinkedList.sol";

contract SponsorPool {
    SortedLinkedList.Item[] public sponsorPoolUsers;

    function _addSponsorPoolRecord(address user, uint amount, uint8 stakeId, uint16 prev) internal {
        SortedLinkedList.addNode(sponsorPoolUsers, user, amount, stakeId, prev);
    }

    function _cleanSponsorPoolUsers() internal {
        delete sponsorPoolUsers;
        SortedLinkedList.initNodes(sponsorPoolUsers);
    }
}
