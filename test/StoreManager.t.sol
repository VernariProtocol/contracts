// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/proxy/UUPSProxy.sol";
import "../contracts/StoreManager.sol";
import "../contracts/Store.sol";
import {Vault} from "../contracts/Vault.sol";

contract StoreManagerTest is Test {
    UUPSProxy proxy;
    address admin;
    address store1Owner;
    StoreManager manager;
    StoreManager proxyManager;
    Store store;
    address oracle;
    Vault vault;
    Store store1;

    function setUp() public {
        admin = makeAddr("admin");
        oracle = makeAddr("oracle");
        store1Owner = makeAddr("store1Owner");
        vm.startPrank(admin);
        vault = new Vault();
        // deploy the implementation contract
        StoreManager impl = new StoreManager(oracle);
        proxy = new UUPSProxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address,address)",
                oracle,
                address(vault)
            )
        );
        proxyManager = StoreManager(address(proxy));
        vault.setStoreManager(address(proxyManager));
        vm.stopPrank();
    }

    function createStoreFixture() public {
        vm.startPrank(admin);
        store1 = new Store();
        store1.initialize(address(proxyManager), store1Owner, bytes("the store"), 1, (60 * 60 * 6));
        proxyManager.addCompany(address(store1));
        vm.stopPrank();
    }

    // function test_UpgradeContract() public {
    //     // proxy is the proxy contract that is called
    //     // deploy the new implementation contract
    //     StoreManager impl2 = new StoreManager();
    //     // call the upgradeTo function on the proxy with new implementation address
    //     wrappedV1.upgradeTo(address(impl2));
    //     StoreManager wrappedV2 = StoreManager(address(proxy));
    //     wrappedV2.decrement();
    //     assert(wrappedV2.number() == 41);
    // }

    function test_getChainlinkOracleAddress_ReturnsCorrectAddress() public {
        vm.prank(admin);
        assert(proxyManager.getOracleAddress() == oracle);
    }
}
