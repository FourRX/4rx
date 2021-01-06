// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyERC20Token is ERC20 {
    constructor() ERC20('DUMMY', 'DMY') public {
        _mint(msg.sender, 10000000000000000);
    }
}
