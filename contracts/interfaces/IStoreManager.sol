// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStoreManager {
    function version() external pure returns (string memory);

    function registerOrder(bytes32 orderId, bytes32 company) external;

    function addCompany(address vault) external;
}
