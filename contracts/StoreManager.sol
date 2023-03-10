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
import {FunctionsClient} from "./FunctionsClient.sol";
import {IStoreManager} from "./interfaces/IStoreManager.sol";
import {IStore} from "./interfaces/IStore.sol";
import {Functions} from "./lib/Functions.sol";
import {IVault} from "./interfaces/IVault.sol";

contract StoreManager is
    IStoreManager,
    FunctionsClient,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    AutomationCompatibleInterface,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using Functions for Functions.Request;
    using SafeERC20 for IERC20Metadata;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    IVault i_vault;

    bytes32 jobSpec;
    uint256 interval;
    uint256 jobPayment;

    bytes internal latestError;
    bytes internal lambdaFunction;
    bytes internal lambdaSecrets;
    uint32 internal gasLimit;

    mapping(bytes => EnumerableSet.Bytes32Set) private companyQueue;
    mapping(bytes => bool) private activeCompanies;
    mapping(bytes => address) internal stores;
    mapping(bytes32 => bytes) internal companyRequests;

    event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);
    event FullfillmentError(bytes32 indexed requestId, bytes err, bytes company);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address oracle) FunctionsClient(oracle) initializer {}

    /**
     * @notice Initialize the contract after it has been proxied
     */
    function initialize(address oracle, address vault) public initializer {
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        setOracle(oracle);
        i_vault = IVault(vault);
    }

    function version() public pure returns (string memory) {
        return "0.0.1";
    }

    function registerOrder(bytes32 orderId, bytes memory company) external override nonReentrant whenNotPaused {
        _addToQueue(orderId, company);
    }

    function requestTracking(
        string memory trackingNumber,
        string memory shippingCompany,
        bytes32 orderId,
        bytes memory company
    ) internal {
        Functions.Request memory req;
        req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, string(lambdaFunction));
        req.addInlineSecrets(lambdaSecrets);
        string[4] memory setter = [trackingNumber, shippingCompany, string(abi.encodePacked(orderId)), string(company)];
        string[] memory args = new string[](setter.length);
        for (uint256 i = 0; i < setter.length; i++) {
            args[i] = setter[i];
        }
        req.addArgs(args);

        bytes32 assignedReqID = sendRequest(req, IStore(stores[company]).getSubscriptionId(), gasLimit, tx.gasprice);
        companyRequests[assignedReqID] = company;
    }

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (response.length != 0) {
            (uint8 status, bytes32 orderNumber, bytes memory company) = abi.decode(response, (uint8, bytes32, bytes));
            if (status == uint8(IStore.Status.DELIVERED)) {
                _removeFromQueue(orderNumber, company);
                _updateOrderStatus(orderNumber, company, IStore.Status.DELIVERED);
            } else {
                IStore(stores[company]).getOrder(orderNumber).lastAutomationCheck = block.timestamp;
            }
        } else {
            latestError = err;
            emit FullfillmentError(requestId, err, companyRequests[requestId]);
        }

        emit OCRResponse(requestId, response, err);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        bytes memory company = abi.decode(checkData, (bytes));
        require(activeCompanies[company], "StoreManager: company must be active");
        for (uint256 i = 0; i < companyQueue[company].length(); i++) {
            bytes32 orderId = companyQueue[company].at(i);
            IStore.Order memory order = IStore(stores[company]).getOrder(orderId);
            if (
                order.status == IStore.Status.SHIPPED
                    && block.timestamp - order.lastAutomationCheck > IStore(stores[company]).getAutomationInterval()
            ) {
                upkeepNeeded = true;
                break;
            }
        }

        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override whenNotPaused nonReentrant {
        bytes memory company = abi.decode(performData, (bytes));
        require(activeCompanies[company], "StoreManager: company must be active");
        for (uint256 i = 0; i < companyQueue[company].length(); i++) {
            bytes32 orderId = companyQueue[company].at(i);
            IStore.Order memory order = IStore(stores[company]).getOrder(orderId);
            if (
                order.status == IStore.Status.SHIPPED
                    && block.timestamp - order.lastAutomationCheck > IStore(stores[company]).getAutomationInterval()
            ) {
                requestTracking(order.trackingNumber, order.company, orderId, company);
            }
        }
    }

    function depositOrderAmount(bytes memory company) external payable {
        address store = stores[company];
        require(store != address(0), "StoreManager: store not found");
        i_vault.deposit{value: msg.value}(store);
    }

    // Internal functions ------------------------------------------------------

    function _updateOrderStatus(bytes32 orderId, bytes memory company, IStore.Status status) internal {
        IStore(stores[company]).updateOrderStatus(orderId, status);
    }

    function _removeFromQueue(bytes32 orderId, bytes memory company) internal {
        companyQueue[company].remove(orderId);
    }

    function _addToQueue(bytes32 orderId, bytes memory company) internal {
        require(activeCompanies[company], "StoreManager: company must be active");
        companyQueue[company].add(orderId);
    }

    // Admin functions ---------------------------------------------------------

    /**
     * @notice Add a new company to the StoreManager.
     * @param store the address of the store contract.
     * @dev The company must not be active.
     */
    function addCompany(address store) external override onlyOwner {
        require(store != address(0), "StoreManager: store cannot be zero address");
        bytes memory company = IStore(store).getCompanyName();
        require(!activeCompanies[company], "StoreManager: company must not be active");
        require(stores[company] == address(0), "StoreManager: company must not have a store");
        stores[company] = store;
        activeCompanies[company] = true;
    }

    function setPayment(uint256 payment) public onlyOwner {
        jobPayment = payment;
    }

    function getQueueLength(bytes memory company) external view onlyOwner returns (uint256) {
        return companyQueue[company].length();
    }

    function getOracleAddress() external view onlyOwner returns (address) {
        return getChainlinkOracleAddress();
    }

    function setLambda(bytes calldata lambda) external onlyOwner {
        lambdaFunction = lambda;
    }

    function setSecrets(bytes calldata secrets) external onlyOwner {
        lambdaSecrets = secrets;
    }

    function updateOracleAddress(address oracle) external onlyOwner {
        setOracle(oracle);
    }

    function getVault() external view returns (address) {
        return address(i_vault);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
