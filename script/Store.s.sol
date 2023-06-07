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
        store.addOrder{value: 0.01 ether}(keccak256(abi.encodePacked("seven")), 0.01 ether, true, address(0));


        vm.stopBroadcast();
    }
}
