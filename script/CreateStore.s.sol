// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {StoreFactory} from "../contracts/StoreFactory.sol";
import {StoreManager} from "../contracts/StoreManager.sol";
import {Utils} from "../contracts/utils/Utils.sol";

contract CreateStoreScript is Utils {
    StoreFactory factory;
    StoreManager manager;
    uint256 deployerPrivateKey;
    uint64 subId = 393;
    uint96 autoInterval = 180;

    function run() public {
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        factory = StoreFactory(getValue("storeFactory"));
        manager = StoreManager(getValue("storeManager"));
        address newStore = factory.createStore(getValue("admin"), bytes("company1"), subId, autoInterval);
        manager.addCompany(newStore);

        updateDeployment(newStore, "currentStore");

        vm.stopBroadcast();
    }
}
