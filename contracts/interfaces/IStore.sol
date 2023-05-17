// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStore {
    enum Status {
        PENDING,
        SHIPPED,
        DELIVERED,
        RETURNED,
        CANCELLED
    }

    struct Order {
        bytes32 Id;
        string trackingNumber;
        string company;
        Status status;
        uint256 lastUpdate;
        bool active;
        bytes[] notes;
        uint256 lastAutomationCheck;
        uint256 value;
    }

    function version() external pure returns (string memory);

    function addOrder(bytes32 orderNumber, uint256 amount, bool gasToken, address tokenAsset) external payable;

    function updateOrderStatus(bytes32 orderId, Status status) external;

    function getOrder(bytes32 orderId) external view returns (Order memory);

    function initialize(address manager, address owner, bytes memory company, uint64 subId, uint96 automationInterval)
        external;

    function getCompanyName() external view returns (string memory);

    function getSubscriptionId() external view returns (uint64);

    function getAutomationInterval() external view returns (uint96);

    function withdrawGasToken() external;
    function withdrawTokenAsset(address token) external;

    function getWithdrawableGasTokenAmount() external view returns (uint256);
    function getWithdrawableAssetTokenAmount(address token) external view returns (uint256);
    function getLockedGasTokenAmount() external view returns (uint256);
    function getLockedAssetTokenAmount(address token) external view returns (uint256);

    function addWhitelistedToken(address token) external;
    function removeWhitelistedToken(address token) external;

    function addWhiteListedAddress(address addr) external;
    function removeWhiteListedAddress(address addr) external;
}
