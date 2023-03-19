// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    address public manager;
    mapping(address => uint256) public lockedBalances;
    mapping(address => uint256) public unlockedBalances;

    modifier onlyManager() {
        require(msg.sender == manager, "Vault: only manager can call this function");
        _;
    }

    constructor() {}

    function deposit(address account) external payable onlyManager {
        lockedBalances[account] += msg.value;
    }

    function withdraw(uint256 amount, address payable account) external onlyManager {
        require(amount <= unlockedBalances[account], "Vault: insufficient funds");
        unlockedBalances[account] -= amount;
        (bool sent,) = account.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function unlockFunds(address account, uint256 amount) external onlyManager {
        unlockedBalances[account] += amount;
        lockedBalances[account] -= amount;
    }

    function withdrawableAmount(address account) external view returns (uint256) {
        return unlockedBalances[account];
    }

    function getLockedBalance(address account) external view returns (uint256) {
        return lockedBalances[account];
    }

    function setStoreManager(address managerAddress) external onlyOwner {
        manager = managerAddress;
    }
}
