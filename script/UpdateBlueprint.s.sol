// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utils} from "../contracts/utils/Utils.sol";
import {Store} from "../contracts/Store.sol";
import {StoreFactory} from "../contracts/StoreFactory.sol";

contract UpdateBlueprintScript is Utils {
    Store blueprint;
    StoreFactory factory;
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
        factory = StoreFactory(getValue("storeFactory"));
        factory.updateBeaconInstance(address(blueprint), "v0.0.2");

        vm.stopBroadcast();
    }
}
