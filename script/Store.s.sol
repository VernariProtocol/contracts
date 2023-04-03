// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utils} from "../contracts/utils/Utils.sol";
import {Store} from "../contracts/Store.sol";
import {StoreManager} from "../contracts/StoreManager.sol";

contract StoreScript is Utils {
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
        store = Store(payable(getValue("currentStore")));
        manager = StoreManager(getValue("storeManager"));
        // store.addOrder{value: 0.01 ether}(keccak256(abi.encodePacked("four")), 0.01 ether);
        store.updateOrder(keccak256(abi.encodePacked("four")), "SHIPPO_DELIVERED", "shippo");
        // store.withdrawVaultFunds(0.02 ether);
        // store.withdraw();
        // address(store).balance;
        // manager.requestTracking("SHIPPO_TRANSIT", "shippo", keccak256(abi.encodePacked("one")), bytes("company1"));

        vm.stopBroadcast();
    }
}
