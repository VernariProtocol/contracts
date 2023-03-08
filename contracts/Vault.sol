// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    address public manager;
    mapping(address => uint256) public balances;

    modifier onlyManager() {
        require(msg.sender == manager, "only manager can call this function");
        _;
    }

    constructor() {}

    function deposit(address account) external payable onlyManager {
        balances[account] += msg.value;
    }

    function withdraw(uint256 amount) public {
        balances[msg.sender] -= amount;
    }

    function withdrawableAmount() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getBalance(address account) public view returns (uint256) {
        return balances[account];
    }

    function setStoreManager(address managerAddress) public onlyOwner {
        manager = managerAddress;
    }
}
