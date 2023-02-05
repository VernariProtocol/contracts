// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IStore {
    enum Status {
        Pending,
        Shipped,
        Delivered,
        Returned,
        Cancelled
    }

    struct Order {
        bytes32 Id;
        string trackingNumber;
        string company;
        Status status;
        uint256 lastUpdate;
        uint256 lastPrice;
        uint256 lastDepth;
        uint256 lastLimit;
        uint256 lastQueue;
        bool active;
        bytes[] notes;
    }

    function version() external pure returns (string memory);

    function addOrder(bytes32 orderNumber, uint256 amount, bytes32 company) external payable;

    function updateOrderStatus(bytes32 orderId, Status status) external;

    function getOrder(bytes32 orderId) external view returns (Order memory);

    function initialize(address manager, address owner, bytes32 company) external;

    function getCompanyName() external view returns (bytes32);
}
