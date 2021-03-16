// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "hardhat/console.sol";

contract SortedLinkedListArray {

    struct Item {
        address user;
        uint16 next;
        uint8 id;
        uint score;
    }

    Item[] items;

    uint16 public constant GUARD = 0;

    constructor() public {
        _resetList();
    }

    function _resetList() internal {
        delete items;
        items.push(Item(address(0), 0, 0, 0));
    }

    function addItem(address user, uint score, uint8 id, uint16 prev) public {
        require(_verifyIndex(score, prev));
        items.push(Item(user, items[prev].next, id, score));
        items[prev].next = uint16(items.length - 1);
        console.log("Array length => ", items.length);
    }

    function updateItem(address user, uint score, uint8 id, uint16 current, uint16 oldPrev, uint16 newPrev) public {
        require(items[oldPrev].next == current);
        require(items[current].user == user);
        require(items[current].id == id);
        items[oldPrev].next = items[current].next;
        addItem(user, score, id, newPrev);
    }

    function getTopKItems(uint k) public view returns (uint[] memory) {
        uint[] memory list = new uint[](k);
        Item memory current = items[0];
        uint16 i = 0;
        while (i < k && current.next != GUARD) {
            current = items[current.next];
            list[i] = current.score;
            i++;
        }

        return list;
    }

    function deleteList() public {
        _resetList();
    }

    function _verifyIndex(uint score, uint16 prev) internal view returns (bool) {
        return prev == 0 || (score <= items[prev].score && score > items[items[prev].next].score);
    }
}
