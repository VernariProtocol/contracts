// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {StoreManager} from "../contracts/StoreManager.sol";

contract NetworkForkTest is Test {
    using stdJson for string;

    StoreManager manager;
    address admin;
    uint256 network;

    function setUp() public {
        network = vm.createSelectFork(vm.rpcUrl("mumbai"));
        admin = makeAddr("admin");
        manager = StoreManager(0x2A351AA96706afD92508c6e769cc95717f1D62bc);
    }

    // function testFork_managerCheckUpkeep() public view {
    //     manager.checkUpkeep(
    //         "0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000008636f6d70616e7931000000000000000000000000000000000000000000000000"
    //     );
    //     // console.log("name: ", v.lastAutomationCheck);
    // }
}
