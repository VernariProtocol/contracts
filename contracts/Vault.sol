// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;

    address public manager;
    mapping(address => uint256) internal lockedGasTokenBalances;
    mapping(address => uint256) internal unlockedGasTokenBalances;
    mapping(address => mapping(address => uint256)) internal lockedTokenBalances;
    mapping(address => mapping(address => uint256)) internal unlockedTokenBalances;
    mapping(address => uint256) internal totalDeposits;

    modifier onlyManager() {
        require(msg.sender == manager, "Vault: only manager can call this function");
        _;
    }
    // User's deposited amount / Total deposits in the vault) * Total aTokens received
    // maybe have automation in vault to automate adding funds to strategy?
    // protocol takes 0 fees but takes a percentage of APY. How to calculate this?
    // needs enough revenue to make paying for automation worth it
    // maybe have a feature to pay out in asset of their choice?
    // buffer in vault so fees arnt too high?

    constructor() {}

    function deposit(address account) external payable onlyManager {
        lockedGasTokenBalances[account] += msg.value;
    }

    // take percentage cut of APY when withdrawing asset
    function depositToken(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        lockedTokenBalances[msg.sender][token] += amount;
        totalDeposits[token] += amount;

        IERC20(token).safeApprove(manager, amount);
    }

    function withdrawGasToken(uint256 amount, address payable account) external onlyManager {
        require(amount <= unlockedGasTokenBalances[account], "Vault: insufficient funds");
        unlockedGasTokenBalances[account] -= amount;
        (bool sent,) = account.call{value: amount}("");
        require(sent, "Failed to send Gas Token");
    }

    function withdrawTokenAsset(uint256 amount, address token, address account) external onlyManager {
        require(amount <= unlockedTokenBalances[account][token], "Vault: insufficient funds");
        unlockedTokenBalances[account][token] -= amount;
        IERC20(token).safeTransfer(account, amount);
    }

    function _addTokenToStrategy() internal {}

    function unlockFunds(address account, uint256 amount) external onlyManager {
        unlockedGasTokenBalances[account] += amount;
        lockedGasTokenBalances[account] -= amount;
    }

    function withdrawableGasTokenAmount(address account) external view returns (uint256) {
        return unlockedGasTokenBalances[account];
    }

    function withdrawableAssetTokenAmount(address account, address token) external view returns (uint256) {
        return unlockedTokenBalances[account][token];
    }

    function getLockedGasTokenBalance(address account) external view returns (uint256) {
        return lockedGasTokenBalances[account];
    }

    function getLockedAssetTokenBalance(address account, address token) external view returns (uint256) {
        return lockedTokenBalances[account][token];
    }

    function setStoreManager(address managerAddress) external onlyOwner {
        manager = managerAddress;
    }
}
