// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@chainlink/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/src/v0.8/ChainlinkClient.sol";
import "./interfaces/IVaultManager.sol";
import "./interfaces/IVault.sol";

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
    IVault public vault;

    EnumerableSet.Bytes32Set private orderQueue;

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

    function registerOrder(bytes32 orderId) external override nonReentrant whenNotPaused {
        addToQueue(orderId);
    }

    function addToQueue(bytes32 orderId) internal {
        EnumerableSet.add(orderQueue, orderId);
    }

    function requestTracking(
        bytes32 specId,
        uint256 payment,
        string memory trackingNumber,
        string memory company,
        bytes32 orderId
    ) internal {
        Chainlink.Request memory req = buildChainlinkRequest(specId, address(this), this.fulfillTracking.selector);
        req.add("trackingNumber", trackingNumber);
        req.add("company", company);
        req.add("orderId", string(abi.encodePacked(orderId)));
        sendOperatorRequest(req, payment);
    }

    function cancelRequest(bytes32 requestId, uint256 payment, bytes4 callbackFunctionId, uint256 expiration)
        external
    {
        cancelChainlinkRequest(requestId, payment, callbackFunctionId, expiration);
    }

    function fulfillTracking(bytes32 requestId, bytes32 orderNumber, uint8 status)
        external
        recordChainlinkFulfillment(requestId)
    {
        // update item and remove from queue if item is delivered
        if (status == uint8(IVault.Status.Delivered)) {
            removeFromQueue(orderNumber);
            vault.updateOrderStatus(orderNumber, IVault.Status.Delivered);
        }
    }

    function removeFromQueue(bytes32 orderId) internal {}

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        for (uint256 i = 0; i < EnumerableSet.length(orderQueue); i++) {
            bytes32 orderId = EnumerableSet.at(orderQueue, i);
            IVault.Order memory order = vault.getOrder(orderId);
            if (order.status == IVault.Status.Shipped) {
                upkeepNeeded = true;
                break;
            }
        }

        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override whenNotPaused nonReentrant {
        for (uint256 i = 0; i < EnumerableSet.length(orderQueue); i++) {
            bytes32 orderId = EnumerableSet.at(orderQueue, i);
            IVault.Order memory order = vault.getOrder(orderId);
            if (order.status == IVault.Status.Shipped) {
                requestTracking(jobSpec, jobPayment, order.trackingNumber, order.company, orderId);
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
}
