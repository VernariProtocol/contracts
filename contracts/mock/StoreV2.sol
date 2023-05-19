// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgrades/contracts/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IStore} from "../interfaces/IStore.sol";
import {IStoreManager} from "../interfaces/IStoreManager.sol";
import {IVault} from "../interfaces/IVault.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract StoreV2 is IStore, Initializable, ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    IStoreManager public storeManager;
    bytes internal companyName;
    uint64 internal subscriptionId;
    uint96 automationCheckInterval;
    mapping(address => bool) internal whitelist;
    mapping(bytes32 => Order) internal orders;
    Order[] public orderList;
    EnumerableSet.AddressSet internal whitelistedTokens;

    event OrderCreated(bytes32 indexed orderNumber, uint256 amount);
    event OrderUpdated(bytes32 indexed orderNumber, Status status);

    modifier onlyAdmin() {
        require(
            msg.sender == address(storeManager) || msg.sender == owner() || whitelist[msg.sender],
            "Store: only an admin can call this function"
        );
        _;
    }

    modifier whitelistedToken(address token, bool gasToken) {
        if (!gasToken) {
            require(whitelistedTokens.contains(token), "Store: token is not whitelisted");
        }
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
        return "v0.0.1";
    }

    /**
     * @notice adds new order to store and locks the amount sent into the vault.
     * @param orderNumber the order ID from internal business
     * @param amount the amount of the order.
     */
    function addOrder(bytes32 orderNumber, uint256 amount, bool gasToken, address tokenAsset)
        external
        payable
        override
        whitelistedToken(tokenAsset, gasToken)
    {
        require(!orders[orderNumber].active, "Store: order already exists");
        if (gasToken) {
            require(msg.value >= amount, "Store: not enough sent");
        } else {
            IERC20(tokenAsset).safeTransferFrom(msg.sender, address(this), amount);
        }

        orders[orderNumber] = Order({
            Id: orderNumber,
            trackingNumber: "",
            company: string(companyName),
            status: Status.PENDING,
            lastUpdate: block.timestamp,
            active: true,
            notes: new bytes[](0),
            lastAutomationCheck: block.timestamp,
            value: amount
        });
        orderList.push(orders[orderNumber]);
        storeManager.registerOrder(orderNumber, companyName);
        if (gasToken) {
            storeManager.depositOrderAmount{value: msg.value}(companyName);
            emit OrderCreated(orderNumber, msg.value);
        } else {
            // depost token asset to vault
            IERC20(tokenAsset).safeApprove(storeManager.getVault(), amount);
            IVault(storeManager.getVault()).depositToken(tokenAsset, amount);
            emit OrderCreated(orderNumber, amount);
        }
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
     * @dev tracking number/shipping company will need to be encrypted.
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

    // TODO: have store owner decide how they want to handle locked funds?
    function addFundsToStrategy() external onlyAdmin {}

    function withdrawVaultGasToken(uint256 amount) external onlyAdmin {
        storeManager.withdrawVaultGasToken(amount);
    }

    function withdrawVaultTokenAsset(uint256 amount, address token) external onlyAdmin {
        storeManager.withdrawVaultTokenAsset(amount, token);
    }

    function getOrder(bytes32 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    function getOrders() external view returns (Order[] memory) {
        return orderList;
    }

    function getCompanyName() external view returns (string memory) {
        return string(companyName);
    }

    function getSubscriptionId() external view returns (uint64) {
        return subscriptionId;
    }

    function getWhitelistedTokens() external view returns (address[] memory) {
        address[] memory _whitelistedTokens = new address[](whitelistedTokens.length());
        for (uint256 i = 0; i < whitelistedTokens.length(); i++) {
            _whitelistedTokens[i] = whitelistedTokens.at(i);
        }
        return _whitelistedTokens;
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
    function getWithdrawableGasTokenAmount() external view returns (uint256) {
        return IVault(storeManager.getVault()).withdrawableGasTokenAmount(address(this));
    }

    function getWithdrawableAssetTokenAmount(address token) external view returns (uint256) {
        return IVault(storeManager.getVault()).withdrawableAssetTokenAmount(address(this), token);
    }

    function getLockedGasTokenAmount() external view returns (uint256) {
        return IVault(storeManager.getVault()).getLockedGasTokenBalance(address(this));
    }

    function getLockedAssetTokenAmount(address token) external view returns (uint256) {
        return IVault(storeManager.getVault()).getLockedAssetTokenBalance(address(this), token);
    }

    function addWhiteListedAddress(address addr) external onlyOwner {
        whitelist[addr] = true;
    }

    function removeWhiteListedAddress(address addr) external onlyOwner {
        whitelist[addr] = false;
    }

    function addWhitelistedToken(address token) external onlyOwner {
        whitelistedTokens.add(token);
    }

    function removeWhitelistedToken(address token) external onlyOwner {
        whitelistedTokens.remove(token);
    }

    function withdrawGasToken() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Store: no funds to withdraw");
        payable(msg.sender).transfer(amount);
    }

    function withdrawTokenAsset(address token) external onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, "Store: no funds to withdraw");
        IERC20(token).safeTransfer(msg.sender, amount);
    }

    receive() external payable {}
}
