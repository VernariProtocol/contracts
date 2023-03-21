// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import {StoreManager} from "../contracts/StoreManager.sol";

contract UpgradeStoreManagerScript is Script {
    using stdJson for string;

    StoreManager newVersion;
    Config config;
    uint256 deployerPrivateKey;

    struct Config {
        address manager;
        address oracle;
        address vault;
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
        config = configureNetwork("upgrade-manager-config");
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        vm.startBroadcast(deployerPrivateKey);
        newVersion = new StoreManager(config.oracle);
        StoreManager(config.manager).upgradeTo(address(newVersion));

        vm.stopBroadcast();
    }
}
