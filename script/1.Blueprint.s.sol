// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Store} from "../contracts/Store.sol";
import {Utils} from "../contracts/utils/Utils.sol";

contract StoreScript is Utils {
    Store blueprint;
    uint256 deployerPrivateKey;

    function run() public {
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        blueprint = new Store();
        updateDeployment(address(blueprint), "blueprint");
        vm.stopBroadcast();
    }
}
