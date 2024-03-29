// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStoreManager {
    function version() external pure returns (string memory);

    function registerOrder(bytes32 orderId, bytes memory company) external;

    function addCompany(address vault) external;

    function depositOrderAmount(bytes memory company) external payable;

    function getVault() external view returns (address);

    function withdrawVaultGasToken(uint256 amount) external;

    function withdrawVaultTokenAsset(uint256 amount, address token) external;

    function automationRegistry() external view returns (address);
}
