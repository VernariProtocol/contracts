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
import {IVaultManager} from "./interfaces/IVaultManager.sol";
import {IVault} from "./interfaces/IVault.sol";

contract VaultManager is
    IVaultManager,
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
    mapping(bytes32 => bool) private activeCompanues;
    mapping(bytes32 => address) internal vaults;

    /**
     * @param link the LINK token address.
     * @param oracle the Operator.sol contract address.
     * @param spec the Chainlink job spec ID.
     */
    function initialize(address oracle, bytes32 spec, address link) public initializer {
        require(oracle != address(0), "Vault: oracle cannot be zero address");
        require(link != address(0), "Vault: link cannot be zero address");
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
        return "1.0.0";
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function registerOrder(bytes32 orderId, bytes32 company) external override nonReentrant whenNotPaused {
        _addToQueue(orderId, company);
    }

    function _addToQueue(bytes32 orderId, bytes32 company) internal {
        require(activeCompanues[company], "Vault: company must be active");
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
        if (status == uint8(IVault.Status.Delivered)) {
            removeFromQueue(orderNumber);
            _updateOrderStatus(orderNumber, company, IVault.Status.Delivered);
        }
    }

    function removeFromQueue(bytes32 orderId) internal {}

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (bytes32 company) = abi.decode(checkData, (bytes32));
        require(activeCompanues[company], "Vault: company must be active");
        for (uint256 i = 0; i < companyQueue[company].length(); i++) {
            bytes32 orderId = companyQueue[company].at(i);
            IVault.Order memory order = IVault(vaults[company]).getOrder(orderId);
            if (order.status == IVault.Status.Shipped) {
                upkeepNeeded = true;
                break;
            }
        }

        return (upkeepNeeded, performData);
    }

    function addCompany(address vault, bytes32 company) external override onlyOwner {
        require(vault != address(0), "Vault: vault cannot be zero address");
        require(company != bytes32(0), "Vault: company cannot be zero address");
        require(!activeCompanues[company], "Vault: company must not be active");
        require(vaults[company] == address(0), "Vault: company must not have a vault");
        vaults[company] = vault;
        activeCompanues[company] = true;
    }

    function _updateOrderStatus(bytes32 orderId, bytes32 company, IVault.Status status) internal {
        IVault(vaults[company]).updateOrderStatus(orderId, status);
    }

    function performUpkeep(bytes calldata performData) external override whenNotPaused nonReentrant {
        (bytes32 company) = abi.decode(performData, (bytes32));
        require(activeCompanues[company], "Vault: company must be active");
        for (uint256 i = 0; i < companyQueue[company].length(); i++) {
            bytes32 orderId = companyQueue[company].at(i);
            IVault.Order memory order = IVault(vaults[company]).getOrder(orderId);
            if (order.status == IVault.Status.Shipped) {
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
