// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/proxy/UUPSProxy.sol";
import "../contracts/StoreManager.sol";
import "../contracts/Store.sol";

contract StoreManagerTest is Test {
    UUPSProxy proxy;
    address admin;
    StoreManager manager;
    StoreManager proxyManager;
    Store store;
    address oracle;

    function setUp() public {
        admin = makeAddr("admin");
        vm.startPrank(admin);
        oracle = makeAddr("oracle");
        // deploy the implementation contract
        StoreManager impl = new StoreManager(oracle);
        proxy = new UUPSProxy(address(impl), abi.encodeWithSignature("initialize(address)", oracle));
        proxyManager = StoreManager(address(proxy));
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

    function test_registerOrder_RegisterOrderSuccess() public {
        bytes memory s = bytes("some store");
        Store newStore = new Store();
        newStore.initialize(address(proxyManager), admin, s, 1);
        proxyManager.addCompany(address(newStore));
        proxyManager.registerOrder("0x68656c6c6f", s);

        assert(proxyManager.getQueueLength(s) == 1);
    }

    function test_getChainlinkOracleAddress_ReturnsCorrectAddress() public view {
        assert(proxyManager.getOracleAddress() == oracle);
    }
}
