// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgrades/contracts/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgrades/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVault} from "./interfaces/IVault.sol";
import {IVaultManager} from "./interfaces/IVaultManager.sol";

contract Vault is
    IVault,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20Metadata;

    IVaultManager public vaultManager;
    mapping(bytes32 => Order) internal orders;

    event OrderCreated(bytes32 indexed orderNumber, uint256 amount);
    event OrderUpdated(bytes32 indexed orderNumber, Status status);

    modifier onlyAdmin() {
        require(
            msg.sender == address(vaultManager) || msg.sender == owner(), "Vault: only an admin can call this function"
        );
        _;
    }

    /**
     * @param manager the vault manager contract address.
     */
    function initialize(address manager) public initializer {
        require(manager != address(0), "Vault: vault manager cannot be zero address");
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        setManager(manager);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function version() public pure returns (string memory) {
        return "1.0.0";
    }

    function addOrder(bytes32 orderNumber, uint256 amount, bytes32 company) external payable override {
        require(!orders[orderNumber].active, "Vault: order already exists");
        require(msg.value >= amount, "Vault: not enough sent");
        bytes32 orderId = keccak256(abi.encodePacked(orderNumber));
        orders[orderNumber] = Order({
            Id: orderId,
            trackingNumber: "",
            company: "",
            status: Status.Pending,
            lastUpdate: block.timestamp,
            lastPrice: 0,
            lastDepth: 0,
            lastLimit: 0,
            lastQueue: 0,
            active: true,
            notes: new bytes[](0)
        });
        vaultManager.registerOrder(orderId, company);
        emit OrderCreated(orderNumber, msg.value);
    }

    /**
     * ADMIN **********
     */

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function updateOrder(bytes32 orderId, string memory trackingNumber, string memory shippingCompany)
        external
        onlyOwner
    {
        require(orders[orderId].active, "Vault: order does not exist");
        orders[orderId].trackingNumber = trackingNumber;
        orders[orderId].company = shippingCompany;
        orders[orderId].status = Status.Shipped;
        orders[orderId].lastUpdate = block.timestamp;
        emit OrderUpdated(orderId, orders[orderId].status);
    }

    function updateOrderStatus(bytes32 orderId, Status status) external onlyAdmin {
        require(orders[orderId].active, "Vault: order does not exist");
        orders[orderId].status = status;
        orders[orderId].lastUpdate = block.timestamp;
        emit OrderUpdated(orderId, orders[orderId].status);
    }

    function getOrder(bytes32 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setManager(address manager) public onlyOwner {
        vaultManager = IVaultManager(manager);
    }
}
