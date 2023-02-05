// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Initializable} from "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgrades/contracts/security/ReentrancyGuardUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgrades/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AutomationCompatibleInterface} from "@chainlink/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import {ChainlinkClient, Chainlink} from "@chainlink/src/v0.8/ChainlinkClient.sol";
import {IStoreManager} from "./interfaces/IStoreManager.sol";
import {IStore} from "./interfaces/IStore.sol";

contract StoreManager is
    IStoreManager,
    ChainlinkClient,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    AutomationCompatibleInterface,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using Chainlink for Chainlink.Request;
    using SafeERC20 for IERC20Metadata;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 jobSpec;
    uint256 interval;
    uint256 jobPayment;

    mapping(bytes32 => EnumerableSet.Bytes32Set) private companyQueue;
    mapping(bytes32 => bool) private activeCompanies;
    mapping(bytes32 => address) internal stores;

    /**
     * @param link the LINK token address.
     * @param oracle the Operator.sol contract address.
     * @param spec the Chainlink job spec ID.
     */
    function initialize(address oracle, bytes32 spec, address link) public initializer {
        require(oracle != address(0), "StoreManager: oracle cannot be zero address");
        require(link != address(0), "StoreManager: link cannot be zero address");
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        setChainlinkToken(link);
        setChainlinkOracle(oracle);
        setSpec(spec);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function version() public pure returns (string memory) {
        return "0.0.1";
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function registerOrder(bytes32 orderId, bytes32 company) external override nonReentrant whenNotPaused {
        _addToQueue(orderId, company);
    }

    function _addToQueue(bytes32 orderId, bytes32 company) internal {
        require(activeCompanies[company], "StoreManager: company must be active");
        companyQueue[company].add(orderId);
    }

    function requestTracking(
        bytes32 specId,
        uint256 payment,
        string memory trackingNumber,
        string memory shippingCompany,
        bytes32 orderId,
        bytes32 company
    ) internal {
        Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfillTracking.selector);
        req.add("trackingNumber", trackingNumber);
        req.add("shippingCompany", shippingCompany);
        req.add("orderId", string(abi.encodePacked(orderId)));
        req.add("company", string(abi.encodePacked(company)));
        sendOperatorRequest(req, payment);
    }

    function cancelRequest(bytes32 requestId, uint256 payment, bytes4 callbackFunctionId, uint256 expiration)
        external
    {
        cancelChainlinkRequest(requestId, payment, callbackFunctionId, expiration);
    }

    function fulfillTracking(bytes32 requestId, bytes32 company, bytes32 orderNumber, uint8 status)
        external
        recordChainlinkFulfillment(requestId)
    {
        // update item and remove from queue if item is delivered
        if (status == uint8(IStore.Status.Delivered)) {
            removeFromQueue(orderNumber, company);
            _updateOrderStatus(orderNumber, company, IStore.Status.Delivered);
        }
    }

    function removeFromQueue(bytes32 orderId, bytes32 company) internal {
        companyQueue[company].remove(orderId);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (bytes32 company) = abi.decode(checkData, (bytes32));
        require(activeCompanies[company], "StoreManager: company must be active");
        for (uint256 i = 0; i < companyQueue[company].length(); i++) {
            bytes32 orderId = companyQueue[company].at(i);
            IStore.Order memory order = IStore(stores[company]).getOrder(orderId);
            if (order.status == IStore.Status.Shipped) {
                upkeepNeeded = true;
                break;
            }
        }

        return (upkeepNeeded, performData);
    }

    /**
     * @notice Add a new company to the StoreManager.
     * @param store the address of the store contract.
     * @dev The company must not be active.
     */
    function addCompany(address store) external override onlyOwner {
        require(store != address(0), "StoreManager: vault cannot be zero address");
        bytes32 company = IStore(store).getCompanyName();
        require(!activeCompanies[company], "StoreManager: company must not be active");
        require(stores[company] == address(0), "StoreManager: company must not have a store");
        stores[company] = store;
        activeCompanies[company] = true;
    }

    function _updateOrderStatus(bytes32 orderId, bytes32 company, IStore.Status status) internal {
        IStore(stores[company]).updateOrderStatus(orderId, status);
    }

    function performUpkeep(bytes calldata performData) external override whenNotPaused nonReentrant {
        (bytes32 company) = abi.decode(performData, (bytes32));
        require(activeCompanies[company], "StoreManager: company must be active");
        for (uint256 i = 0; i < companyQueue[company].length(); i++) {
            bytes32 orderId = companyQueue[company].at(i);
            IStore.Order memory order = IStore(stores[company]).getOrder(orderId);
            if (order.status == IStore.Status.Shipped) {
                requestTracking(jobSpec, jobPayment, order.trackingNumber, order.company, orderId, company);
            }
        }
    }

    function setOracle(address oracle) external onlyOwner {
        setChainlinkOracle(oracle);
    }

    function setSpec(bytes32 spec) public onlyOwner {
        jobSpec = spec;
    }

    function setPayment(uint256 payment) public onlyOwner {
        jobPayment = payment;
    }

    function getQueueLength(bytes32 company) external view onlyOwner returns (uint256) {
        return companyQueue[company].length();
    }
}
