// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgrades/contracts/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStore} from "../interfaces/IStore.sol";
import {IStoreManager} from "../interfaces/IStoreManager.sol";
import {IVault} from "../interfaces/IVault.sol";

contract StoreV2 is IStore, Initializable, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20Metadata;

    IStoreManager public storeManager;
    bytes internal companyName;
    uint64 internal subscriptionId;
    uint96 automationCheckInterval;
    mapping(address => bool) internal whitelist;
    mapping(bytes32 => Order) internal orders;

    event OrderCreated(bytes32 indexed orderNumber, uint256 amount);
    event OrderUpdated(bytes32 indexed orderNumber, Status status);

    modifier onlyAdmin() {
        require(
            msg.sender == address(storeManager) || msg.sender == owner() || whitelist[msg.sender],
            "Store: only an admin can call this function"
        );
        _;
    }

    /**
     * @param manager the vault manager contract address.
     * @param owner the owner of the store.
     * @param company the company name.
     * @param subId the ChainLink Functions subscription id.
     * @param automationInterval the interval in seconds to check for automation updates.
     * @dev a Chainlink sub ID will need to be set up prior to initializing the contract.
     */
    function initialize(address manager, address owner, bytes memory company, uint64 subId, uint96 automationInterval)
        public
        initializer
    {
        require(owner != address(0), "Store: Store owner cannot be zero address");
        require(manager != address(0), "Store: Store manager cannot be zero address");
        require(subId != 0, "Store: subscription id cannot be zero");
        __Ownable_init();
        __Pausable_init();
        setManager(manager);
        setSubscriptionId(subId);
        transferOwnership(owner);
        companyName = company;
        automationCheckInterval = automationInterval;
    }

    function version() public pure returns (string memory) {
        return "v0.0.2";
    }

    /**
     * @notice adds new order to store and locks the amount sent into the vault.
     * @param orderNumber the order ID from internal business
     * @param amount the amount of the order.
     */
    function addOrder(bytes32 orderNumber, uint256 amount) external payable override {
        require(!orders[orderNumber].active, "Store: order already exists");
        require(msg.value >= amount, "Store: not enough sent");
        bytes32 orderId = keccak256(abi.encodePacked(orderNumber));
        orders[orderNumber] = Order({
            Id: orderId,
            trackingNumber: "",
            company: string(companyName),
            status: Status.PENDING,
            lastUpdate: block.timestamp,
            active: true,
            notes: new bytes[](0),
            lastAutomationCheck: 0,
            value: amount
        });
        storeManager.registerOrder(orderId, companyName);
        storeManager.depositOrderAmount{value: msg.value}(companyName);
        emit OrderCreated(orderNumber, msg.value);
    }

    /**
     * ADMIN **********
     */

    /**
     * @notice updates the order tracking number and shipping company.
     * @param orderId the order id.
     * @param trackingNumber the tracking number.
     * @param shippingCompany the shipping company.
     * @dev can only be called by the owner (company).
     * @dev called by store owner when the order is shipped.
     */
    function updateOrder(bytes32 orderId, string memory trackingNumber, string memory shippingCompany)
        external
        onlyOwner
    {
        require(orders[orderId].active, "Store: order does not exist");
        orders[orderId].trackingNumber = trackingNumber;
        orders[orderId].company = shippingCompany;
        orders[orderId].status = Status.SHIPPED;
        orders[orderId].lastUpdate = block.timestamp;
        emit OrderUpdated(orderId, orders[orderId].status);
    }

    /**
     * @notice updates the order status.
     * @param orderId the order id.
     * @param status the order status.
     * @dev can be called by either the owner or the store manager.
     * @dev called by store manager when the order is fulfilled via automation.
     */
    function updateOrderStatus(bytes32 orderId, Status status) external onlyAdmin {
        require(orders[orderId].active, "Store: order does not exist");
        orders[orderId].status = status;
        orders[orderId].lastUpdate = block.timestamp;
        emit OrderUpdated(orderId, orders[orderId].status);
    }

    function getOrder(bytes32 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    function getCompanyName() external view returns (bytes memory) {
        return companyName;
    }

    function getSubscriptionId() external view onlyAdmin returns (uint64) {
        return subscriptionId;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setManager(address manager) public onlyOwner {
        storeManager = IStoreManager(manager);
    }

    function setSubscriptionId(uint64 subId) public onlyOwner {
        subscriptionId = subId;
    }

    function getAutomationInterval() external view returns (uint96) {
        return automationCheckInterval;
    }

    /**
     * @notice the amount available to withdraw from finished orders.
     */
    function getWithdrawableAmount() external view returns (uint256) {
        return IVault(storeManager.getVault()).withdrawableAmount(address(this));
    }

    function addWhiteListedAddress(address addr) external onlyOwner {
        whitelist[addr] = true;
    }

    function removeWhiteListedAddress(address addr) external onlyOwner {
        whitelist[addr] = false;
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Store: no funds to withdraw");
        payable(msg.sender).transfer(amount);
    }
}
