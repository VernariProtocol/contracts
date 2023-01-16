// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/proxy/UUPSProxy.sol";
import "../contracts/VernariManager.sol";

contract ProxyTest is Test {
    UUPSProxy proxy;
    address admin;
    Manager manager;

    function setUp() public {
        admin = vm.envAddress("LOCAL_ADMIN");
    }

    function testUpgrade() public {
        vm.startPrank(admin);

        // deploy the implementation contract
        Manager impl = new Manager();

        // proxy is the proxy contract that is called
        proxy = new UUPSProxy(address(impl), abi.encodeWithSignature("initialize()"));
        Manager wrappedV1 = Manager(address(proxy));

        wrappedV1.setNumber(42);

        // deploy the new implementation contract
        // Manager impl2 = new Manager();
        // // call the upgradeTo function on the proxy with new implementation address
        // wrappedV1.upgradeTo(address(impl2));
        // Manager wrappedV2 = Manager(address(proxy));
        // wrappedV2.decrement();
        // assert(wrappedV2.number() == 41);
    }
}
