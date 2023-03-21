// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import {Store} from "../contracts/Store.sol";
import {StoreManager} from "../contracts/StoreManager.sol";

contract StoreScript is Script {
    using stdJson for string;

    Store store;
    StoreManager manager;
    uint256 deployerPrivateKey;

    function run() public {
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        vm.startBroadcast(deployerPrivateKey);
        store = Store(payable(0x1EE8fD6f073d019857f8C08CAeE2ff83f8AA3f7d));
        manager = StoreManager(0x7630bE18D3e46e4E1d5bAeaE15707cA15Da4CD68);
        // store.addOrder{value: 0.01 ether}(keccak256(abi.encodePacked("one")), 0.01 ether);
        // store.updateOrder(keccak256(abi.encodePacked("one")), "SHIPPO_DELIVERED", "shippo");
        // store.withdrawVaultFunds(0.01 ether);
        address(store).balance;
        // manager.requestTracking("SHIPPO_TRANSIT", "shippo", keccak256(abi.encodePacked("one")), bytes("company1"));

        vm.stopBroadcast();
    }
}
