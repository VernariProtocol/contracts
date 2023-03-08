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
        bytes memory s = bytes("some store");
        vm.startPrank(admin);
        store1 = new Store();
        store1.initialize(
            address(proxyManager),
            store1Owner,
            bytes("the store"),
            1,
            (60 * 60 * 6)
        );
        proxyManager.addCompany(address(store1));
        vm.stopPrank();
    }

    function testUpgrade() public {
        // proxy is the proxy contract that is called
        // deploy the new implementation contract
        // Manager impl2 = new Manager();
        // // call the upgradeTo function on the proxy with new implementation address
        // wrappedV1.upgradeTo(address(impl2));
        // Manager wrappedV2 = Manager(address(proxy));
        // wrappedV2.decrement();
        // assert(wrappedV2.number() == 41);
    }

    function test_getChainlinkOracleAddress_ReturnsCorrectAddress() public {
        vm.prank(admin);
        assert(proxyManager.getOracleAddress() == oracle);
    }

    function test_addOrder_AddsNewOrderAndUpdatesVault() public {
        createStoreFixture();
        address user = makeAddr("user");
        vm.prank(user);
        vm.deal(user, 1 ether);
        store1.addOrder{value: 1 ether}(
            keccak256(abi.encodePacked("some order")),
            1 ether
        );
        vm.prank(admin);
        assertEq(proxyManager.getQueueLength(bytes("the store")), 1);
        assertEq(address(vault).balance, 1 ether);
        assertEq(vault.getBalance(address(store1)), 1 ether);
    }

    function testRevert_addOrder_NotEnoughGasTokenSent() public {
        createStoreFixture();
        address user = makeAddr("user");
        vm.prank(user);
        vm.deal(user, 1 ether);
        vm.expectRevert("Store: not enough sent");
        store1.addOrder{value: 1 ether}(
            keccak256(abi.encodePacked("some order")),
            2 ether
        );
    }

    function testRevert_addOrder_OrderAlreadyExists() public {
        createStoreFixture();
        address user = makeAddr("user");
        vm.prank(user);

        vm.deal(user, 1 ether);
        store1.addOrder{value: 1 ether}(
            keccak256(abi.encodePacked("some order")),
            1 ether
        );
        vm.deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert("Store: order already exists");
        store1.addOrder{value: 1 ether}(
            keccak256(abi.encodePacked("some order")),
            1 ether
        );
    }

    function test_getWithdrawableAmount_getAmount() public {
        createStoreFixture();
        address user = makeAddr("user");
        vm.prank(user);
        vm.deal(user, 1 ether);
        store1.addOrder{value: 1 ether}(
            keccak256(abi.encodePacked("some order")),
            1 ether
        );
        vm.prank(admin);
        assertEq(proxyManager.getQueueLength(bytes("the store")), 1);
        assertEq(address(vault).balance, 1 ether);
        assertEq(vault.getBalance(address(store1)), 1 ether);
        assertEq(store1.getWithdrawableAmount(), 1 ether);
    }
}
