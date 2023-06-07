// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IPool} from "@aave/interfaces/IPool.sol";
import {IAToken} from "@aave/interfaces/IAToken.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgrades/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgrades/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin-upgrades/contracts/proxy/utils/Initializable.sol";

contract Vault is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    uint256 private constant BASIS_POINTS_TOTAL = 10000;
    address public manager;
    uint256 public withdrawalFee;

    mapping(address => uint256) internal lockedGasTokenBalances;
    mapping(address => uint256) internal unlockedGasTokenBalances;
    mapping(address => mapping(address => uint256)) internal lockedTokenBalances;
    mapping(address => mapping(address => uint256)) internal unlockedTokenBalances;
    mapping(address => uint256) internal accumulatedFees;

    // total deposits in vault
    mapping(address => uint256) internal totalDeposits;
    // asset to pool mapping
    mapping(address => address) internal assetToPool;

    modifier onlyManager() {
        require(msg.sender == manager, "Vault: only manager can call this function");
        _;
    }
    // User's deposited amount / Total deposits in the vault) * Total aTokens received
    // maybe have automation in vault to automate adding funds to strategy?
    // protocol takes 0 fees but takes a percentage of APY. How to calculate this?
    // needs enough revenue to make paying for automation worth it
    // maybe have a feature to pay out in asset of their choice?
    // buffer in vault so fees arnt too high?

       /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _manager) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        manager = _manager;
        withdrawalFee = 0;
    }

    function deposit(address account) external payable onlyManager {
        lockedGasTokenBalances[account] += msg.value;
    }

    // take percentage cut of APY when withdrawing asset
    function depositToken(address token, uint256 amount) external {
        IPool aToken = IPool(assetToPool[token]);
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        lockedTokenBalances[msg.sender][token] += amount;
        totalDeposits[token] += amount;

        IERC20(token).safeApprove(manager, amount);
        aToken.supply(token, amount, address(this), 0);
    }

    function withdrawGasToken(uint256 amount, address payable account) external onlyManager {
        require(amount <= unlockedGasTokenBalances[account], "Vault: insufficient funds");
        unlockedGasTokenBalances[account] -= amount;
        (bool sent,) = account.call{value: amount}("");
        require(sent, "Failed to send Gas Token");
    }

    function withdrawTokenAsset(uint256 amount, address token, address account) external onlyManager {
        uint256 _userShare = unlockedTokenBalances[account][token];
        require(amount <= _userShare, "Vault: insufficient funds");
        IPool aPool = IPool(assetToPool[token]);
        IAToken aToken = IAToken(aPool.getReserveData(token).aTokenAddress);

        // calculate user's share of yield
        uint256 totalYield = aToken.balanceOf(address(this)) - totalDeposits[token] - accumulatedFees[token];
        uint256 userYield = (_userShare * totalYield) / (aToken.balanceOf(address(this)) - accumulatedFees[token]);
        uint256 protocolFee = _getWithdrawalFeeAmount(userYield);
        uint256 actualYield = userYield - protocolFee;

        unlockedTokenBalances[account][token] -= amount;
        totalDeposits[token] -= amount;
        accumulatedFees[token] += protocolFee;
        aPool.withdraw(token, amount + actualYield, account);
    }

    function getYieldTotal(address token) external view returns (uint256) {
        IPool aPool = IPool(assetToPool[token]);
        IAToken aToken = IAToken(aPool.getReserveData(token).aTokenAddress);
        return aToken.balanceOf(address(this)) - totalDeposits[token];
    }

    function getYield(address account, address token) external view returns (uint256) {
        IPool aPool = IPool(assetToPool[token]);
        IAToken aToken = IAToken(aPool.getReserveData(token).aTokenAddress);
        uint256 totalYield = aToken.balanceOf(address(this)) - totalDeposits[token];
        uint256 userYield = ((lockedTokenBalances[account][token] + unlockedTokenBalances[account][token]) * totalYield)
            / aToken.balanceOf(address(this));
        return userYield;
    }

    function unlockFunds(address account, uint256 amount) external onlyManager {
        unlockedGasTokenBalances[account] += amount;
        lockedGasTokenBalances[account] -= amount;
    }

    function withdrawableGasTokenAmount(address account) external view returns (uint256) {
        return unlockedGasTokenBalances[account];
    }

    function withdrawableAssetTokenAmount(address account, address token) external view returns (uint256) {
        return unlockedTokenBalances[account][token];
    }

    function getLockedGasTokenBalance(address account) external view returns (uint256) {
        return lockedGasTokenBalances[account];
    }

    function getLockedAssetTokenBalance(address account, address token) external view returns (uint256) {
        return lockedTokenBalances[account][token];
    }

    function setStoreManager(address managerAddress) external onlyOwner {
        manager = managerAddress;
    }

    /**
     * @notice returns the withdrawal fee to be paid on a withdrawal
     * @param _amount amount to withdraw
     * @return amount of tokens to be paid on withdrawal
     *
     */
    function _getWithdrawalFeeAmount(uint256 _amount) internal view returns (uint256) {
        return (_amount * withdrawalFee) / BASIS_POINTS_TOTAL;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
