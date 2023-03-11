// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/proxy/UUPSProxy.sol";
import "../contracts/StoreFactory.sol";
import "../contracts/StoreManager.sol";
import "../contracts/Store.sol";
import {Vault} from "../contracts/Vault.sol";
import {StoreV2} from "../contracts/mock/StoreV2.sol";

contract StoreManagerTest is Test {
    UUPSProxy proxy;
    address admin;
    address store1Owner;
    StoreFactory factory;
    StoreManager proxyManager;
    Store blueprintv1;
    StoreV2 blueprintv2;
    address oracle;
    Vault vault;
    Store impl1;

    function setUp() public {
        admin = makeAddr("admin");
        oracle = makeAddr("oracle");
        store1Owner = makeAddr("store1Owner");
        vm.startPrank(admin);
        vault = new Vault();
        blueprintv1 = new Store();

        createManagerProxy();

        factory = new StoreFactory(address(blueprintv1), "v0.0.1", address(proxyManager));
        vault.setStoreManager(address(proxyManager));
        vm.stopPrank();
    }

    function createManagerProxy() public {
        // deploy the implementation contract
        StoreManager impl = new StoreManager(oracle);
        // deploy the proxy contract
        proxy = new UUPSProxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address,address)",
                oracle,
                address(vault)
            )
        );
        proxyManager = StoreManager(address(proxy));
    }

    function test_createStore_createStoreFromFactory() public {
        vm.startPrank(admin);
        address storeAddress = factory.createStore(store1Owner, bytes("the store"), 1, (60 * 60 * 6));
        vm.stopPrank();
        Store store = Store(storeAddress);
        assertEq(store.owner(), store1Owner);
        assertEq(store.getCompanyName(), "the store");
        assertEq(store.version(), "v0.0.1");
    }

    function test_createStore_createStoreAndUpgrade() public {
        vm.startPrank(admin);
        address storeAddress = factory.createStore(store1Owner, bytes("the store"), 1, (60 * 60 * 6));

        Store store = Store(storeAddress);
        assertEq(store.owner(), store1Owner);
        assertEq(store.getCompanyName(), "the store");
        assertEq(store.version(), "v0.0.1");

        blueprintv2 = new StoreV2();
        factory.updateBeaconInstance(address(blueprintv2), "v0.0.2");
        assertEq(store.version(), "v0.0.2");
        vm.stopPrank();
    }
}
