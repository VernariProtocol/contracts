// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVault {
    function deposit(address account) external payable;

    function withdraw(uint256 amount, address payable account) external;

    function withdrawableAmount(address store) external view returns (uint256);

    function unlockFunds(address account, uint256 amount) external;
}
