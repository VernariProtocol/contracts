// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IVault {
    function deposit(address account) external payable;

    function withdrawGasToken(uint256 amount, address payable account) external;

    function withdrawTokenAsset(uint256 amount, address token, address account) external;

    function withdrawableGasTokenAmount(address account) external view returns (uint256);
    function withdrawableAssetTokenAmount(address account, address token) external view returns (uint256);

    function getLockedGasTokenBalance(address account) external view returns (uint256);
    function getLockedAssetTokenBalance(address account, address token) external view returns (uint256);

    function unlockFunds(address account, uint256 amount) external;
    function depositToken(address token, uint256 amount) external;
}
