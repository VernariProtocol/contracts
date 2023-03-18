// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import {StoreManager} from "../contracts/StoreManager.sol";

contract SetLambdaScript is Script {
    using stdJson for string;

    StoreManager manager;
    uint256 deployerPrivateKey;

    function getLambda(string memory input) internal view returns (bytes memory) {
        /// @dev Stringify the lambda function
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, input);
        string memory lambda = vm.readFile(path);
        return bytes(lambda);
    }

    function run() public {
        bytes memory lambda = getLambda("/lambdas/shipping-oracle.js");
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        manager = StoreManager(0x2A351AA96706afD92508c6e769cc95717f1D62bc);

        manager.setLambda(lambda);

        vm.stopBroadcast();
    }
}
