// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract Events {
    event Deposit(address user, address uplink, uint amount);
    event Withdraw(address user, uint amount);
    event ReInvest(address user, uint amount);
    event Exited(address user);
}
