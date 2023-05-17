// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/proxy/UUPSProxy.sol";
import "../contracts/StoreManager.sol";
import "../contracts/Store.sol";
import {Vault} from "../contracts/Vault.sol";
import {StoreManagerV2} from "../contracts/mock/StoreManagerV2.sol";

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
    StoreManagerV2 implV2;

    function setUp() public {
        admin = makeAddr("admin");
        oracle = makeAddr("oracle");
        store1Owner = makeAddr("store1Owner");
        vm.startPrank(admin);
        vault = new Vault();

        StoreManager impl = new StoreManager(oracle);
        proxy = new UUPSProxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address,address,uint32)",
                oracle,
                address(vault),
                500_000
            )
        );
        proxyManager = StoreManager(address(proxy));
        vault.setStoreManager(address(proxyManager));
        vm.stopPrank();
    }

    function createStoreFixture() public {
        vm.startPrank(admin);
        store1 = new Store();
        store1.initialize(address(proxyManager), store1Owner, bytes("the store"), 1, (60));
        proxyManager.addCompany(address(store1));
        vm.stopPrank();
    }

    function automationFixture() public {
        createStoreFixture();
        address user = makeAddr("user");
        vm.prank(user);
        vm.deal(user, 1 ether);
        store1.addOrder{value: 1 ether}(keccak256(abi.encodePacked("some order")), 1 ether, true, address(0));
        vm.prank(store1Owner);
        store1.updateOrder(keccak256(abi.encodePacked("some order")), "tracking", "usps");
    }

    function test_upgrade_upgradeStoreManager() public {
        vm.startPrank(admin);

        implV2 = new StoreManagerV2(oracle);
        proxyManager.upgradeTo(address(implV2));
        assertEq(proxyManager.version(), "v0.0.2");
        vm.stopPrank();
    }

    function testRevert_upgrade_upgradeFailsWhenCalledByRandomAddress() public {
        vm.startPrank(store1Owner);

        implV2 = new StoreManagerV2(oracle);
        vm.expectRevert("Ownable: caller is not the owner");
        proxyManager.upgradeTo(address(implV2));
        vm.stopPrank();
    }

    function test_getChainlinkOracleAddress_ReturnsCorrectAddress() public {
        vm.prank(admin);
        assert(proxyManager.getOracleAddress() == oracle);
    }

    function test_checkUpkeep_returnsTrue() public {
        automationFixture();
        vm.warp(block.timestamp + 61);
        (bool upkeepNeeded,) = proxyManager.checkUpkeep(bytes("the store"));
        assertTrue(upkeepNeeded);
    }

    function testRevert_checkUpkeep_storeDoesntExist() public {
        automationFixture();
        vm.expectRevert("StoreManager: company must be active");
        proxyManager.checkUpkeep(bytes("doesnt exist"));
    }

    // function test_performUpkeep_returnsTrue() public {
    //     automationFixture();
    //     vm.warp(block.timestamp + 61);
    //     proxyManager.performUpkeep(bytes("the store"));
    // }

    function test_checkOracle() public {}

    function test_bytes32ToString() public view {
        bytes32 x = keccak256(abi.encodePacked("one"));
        string memory s = proxyManager._bytes32ToHexString(x);
        console.log(s);
    }
}
