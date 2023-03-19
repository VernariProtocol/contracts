// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import {Store} from "../contracts/Store.sol";

contract StoreScript is Script {
    using stdJson for string;

    Store store;
    uint256 deployerPrivateKey;

    function run() public {
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        vm.startBroadcast(deployerPrivateKey);
        store = Store(payable(0xC1dca3133E8e23a5522099d4cCe0e2bc21ef5C19));
        // store.addOrder{value: 0.01 ether}(keccak256(abi.encodePacked("one")), 0.01 ether);
        store.updateOrder(keccak256(abi.encodePacked("one")), "SHIPPO_TRANSIT", "shippo");

        vm.stopBroadcast();
    }
}
