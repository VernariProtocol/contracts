// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import {StoreFactory} from "../contracts/StoreFactory.sol";
import {StoreManager} from "../contracts/StoreManager.sol";

contract CreateStoreScript is Script {
    using stdJson for string;

    StoreFactory factory;
    StoreManager manager;
    uint256 deployerPrivateKey;
    Config config;

    struct Config {
        address admin;
        address factory;
        address manager;
        uint64 subId;
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
        config = configureNetwork("address-config");
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        factory = StoreFactory(config.factory);
        manager = StoreManager(config.manager);
        address newStore = factory.createStore(config.admin, bytes("company1"), config.subId, 180);
        manager.addCompany(newStore);

        vm.stopBroadcast();
    }
}
