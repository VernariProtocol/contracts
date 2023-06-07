// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utils} from "../contracts/utils/Utils.sol";
import {StoreManager} from "../contracts/StoreManager.sol";

contract UpgradeStoreManagerScript is Utils {
    StoreManager newVersion;
    uint256 deployerPrivateKey;

    function run() public {
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        vm.startBroadcast(deployerPrivateKey);
        newVersion = new StoreManager(getValue("oracle"));
        StoreManager(getValue("storeManager")).upgradeTo(address(newVersion));

        vm.stopBroadcast();
    }
}
