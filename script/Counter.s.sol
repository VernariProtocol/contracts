// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract CounterScript is Script {
    address admin;

    function setUp() public {
        admin = vm.envAddress("LOCAL_ADMIN");
    }

    function run() public {
        // vm.broadcast();
    }
}
