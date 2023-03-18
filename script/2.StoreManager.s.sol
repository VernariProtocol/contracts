// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import {StoreManager} from "../contracts/StoreManager.sol";
import {UUPSProxy} from "../contracts/proxy/UUPSProxy.sol";
import {Vault} from "../contracts/Vault.sol";

contract StoreManagerScript is Script {
    using stdJson for string;

    StoreManager impl;
    Vault vault;
    UUPSProxy proxy;
    uint256 deployerPrivateKey;
    Config config;

    struct Config {
        address oracle;
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
        config = configureNetwork("manager-config");
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);

        impl = new StoreManager(config.oracle);
        vault = new Vault();
        proxy = new UUPSProxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address,address)",
                config.oracle,
                address(vault)
            )
        );
        vault.setStoreManager(address(proxy));
        console.log("StoreManager address: ", address(proxy));
        vm.stopBroadcast();
    }
}
