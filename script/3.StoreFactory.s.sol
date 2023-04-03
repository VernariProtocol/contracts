// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {StoreFactory} from "../contracts/StoreFactory.sol";
import {Utils} from "../contracts/utils/Utils.sol";

contract StoreFactoryScript is Utils {
    StoreFactory storeFactory;
    uint256 deployerPrivateKey;

    /**
     *
     * @notice blueprint is the address of the deployed Store implementation
     */

    function run() public {
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        storeFactory = new StoreFactory(
            getValue("blueprint"),
            getStringValue("version"),
            getValue("storeManager")

        );
        updateDeployment(address(storeFactory), "storeFactory");

        vm.stopBroadcast();
    }
}
