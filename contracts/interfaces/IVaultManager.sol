// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVaultManager {
    function version() external pure returns (string memory);

    function registerOrder(bytes32 orderId) external;
}
