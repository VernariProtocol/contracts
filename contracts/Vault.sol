// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrades/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgrades/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "./interfaces/IVault.sol";

contract Vault is
    IVault,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    AutomationCompatibleInterface,
    PausableUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20Metadata;

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function version() public pure returns (string memory) {
        return "1.0.0";
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (uint256 limit, uint256 minDepth, uint8 queueId) = abi.decode(checkData, (uint256, uint256, uint8));

        return (upkeepNeeded, performData);
    }

    function performUpkeep(bytes calldata performData) external override whenNotPaused nonReentrant {
        (uint256 limit, uint256 depth, uint8 queueId) = abi.decode(performData, (uint256, uint256, uint8));
    }

    /**
     * ADMIN **********
     */

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}
