// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import {StoreFactory} from "../contracts/StoreFactory.sol";

contract StoreFactoryScript is Script {
    using stdJson for string;

    StoreFactory storeFactory;
    uint256 deployerPrivateKey;
    Config config;

    /**
     *
     * @notice blueprint is the address of the deployed Store implementation
     */

    struct Config {
        address blueprint;
        address functionsRegistry;
        address storeManager;
        string version;
    }

    function configureNetwork(string memory input) internal view returns (Config memory) {
        string memory inputDir = string.concat(vm.projectRoot(), "/script/input/");
        string memory chainDir = string.concat(vm.toString(block.chainid), "/");
        string memory file = string.concat(input, ".json");
        string memory data = vm.readFile(string.concat(inputDir, chainDir, file));
        bytes memory rawConfig = data.parseRaw("");
        return abi.decode(rawConfig, (Config));
    }

    function run() public {
        config = configureNetwork("factory-config");
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        storeFactory = new StoreFactory(
            config.blueprint,
            config.version,
            config.storeManager

        );

        vm.stopBroadcast();
    }
}
