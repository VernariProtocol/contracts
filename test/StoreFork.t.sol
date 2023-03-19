// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {Store} from "../contracts/Store.sol";

contract NetworkForkTest is Test {
    using stdJson for string;

    Store store;
    address admin;
    uint256 network;

    function setUp() public {
        network = vm.createSelectFork(vm.rpcUrl("mumbai"));
        admin = makeAddr("admin");
        store = Store(payable(0x8FC5e074e6F4faa87fc8B48558bbca468c34e793));
    }

    function testFork_storeVersion() public view {
        Store.Order memory v = store.getOrder(0x23dc111d7c3ad1df9806ce1e8eb4f55f57dba117339c545e7593d1f6c3b02662);
        console.log("name: ", v.lastAutomationCheck);
    }

    function testFork_getWithdrawableAMount() public view {
        uint256 v = store.getWithdrawableAmount();
        console.log("name: ", v);
    }

    function testFork_getName() public view {
        bytes memory v = store.getCompanyName();
        console.log("name: ", string(v));
    }
}
