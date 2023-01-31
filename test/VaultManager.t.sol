// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/proxy/UUPSProxy.sol";
import "../contracts/VaultManager.sol";

contract VaultManagerTest is Test {
    UUPSProxy proxy;
    address admin;
    VaultManager manager;
    VaultManager proxyManager;


    function setUp() public {
        admin = makeAddr("admin");
        vm.startPrank(admin);
        // deploy the implementation contract
        VaultManager impl = new VaultManager();
        proxy =
        new UUPSProxy(address(impl), abi.encodeWithSignature("initialize(address,bytes32,address)", admin, "0x68656c6c6f", admin));
        proxyManager = VaultManager(address(proxy));
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

    function testAddToQueue() public {
        proxyManager.registerOrder("0x68656c6c6f");

        assert(proxyManager.getQueueLength() == 1);
    }
}
