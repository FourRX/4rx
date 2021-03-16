// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


library SortedLinkedList {

    struct Item {
        address user;
        uint16 next;
        uint8 id;
        uint score;
    }

    uint16 internal constant GUARD = 0;

    function addNode(Item[] storage items, address user, uint score, uint8 id, uint16 prev) internal {
        require(_verifyIndex(items, score, prev));
        items.push(Item(user, items[prev].next, id, score));
        items[prev].next = uint16(items.length - 1);
    }

    function updateNode(Item[] storage items, address user, uint score, uint8 id, uint16 current, uint16 oldPrev, uint16 newPrev) internal {
        require(items[oldPrev].next == current);
        require(items[current].user == user);
        require(items[current].id == id);
        items[oldPrev].next = items[current].next;
        addNode(items, user, score, id, newPrev);
    }

    function initNodes(Item[] storage items) internal {
        items.push(Item(address(0), 0, 0, 0));
    }

    function _verifyIndex(Item[] storage items, uint score, uint16 prev) internal view returns (bool) {
        return prev == 0 || (score <= items[prev].score && score > items[items[prev].next].score);
    }
}
