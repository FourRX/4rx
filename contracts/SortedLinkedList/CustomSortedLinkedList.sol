//pragma solidity ^0.6.12;
//
//import "hardhat/console.sol";
//import "../libs/SortedLinkedList.sol";
//
//contract CustomSortedLinkedList {
//
//    SortedLinkedList.Item[] items;
//
//    address constant public GUARD = address(0);
//
//    function addItem(address user, uint score, address prev) public {
//        SortedLinkedList.addNode(items, user, uint8(score), score, prev);
//    }
//
//    function updateItem(address user, uint newScore, address oldPrev, address newPrev) public {
//        SortedLinkedList.updateNode(items, user, uint8(newScore), newScore, oldPrev, newPrev);
//    }
//
//    function deleteMapping() public {
//        SortedLinkedList.deleteList(items);
//    }
//
//    function getList(uint k) public view returns (address[] memory) {
//        return SortedLinkedList.getTopKNodes(items, k);
//    }
//}
