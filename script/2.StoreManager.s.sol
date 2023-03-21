// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/StdJson.sol";
import {StoreManager} from "../contracts/StoreManager.sol";
import {UUPSProxy} from "../contracts/proxy/UUPSProxy.sol";
import {Vault} from "../contracts/Vault.sol";

interface FunctionsBillingRegistryInterface {
    function addConsumer(uint64 subscriptionId, address consumer) external;
}

contract StoreManagerScript is Script {
    using stdJson for string;

    StoreManager impl;
    Vault vault;
    UUPSProxy proxy;
    uint256 deployerPrivateKey;
    Config config;

    struct Config {
        uint32 gasLimit;
        address oracle;
        bytes secret;
    }

    function configureNetwork(string memory input) internal view returns (Config memory) {
        string memory inputDir = string.concat(vm.projectRoot(), "/script/input/");
        string memory chainDir = string.concat(vm.toString(block.chainid), "/");
        string memory file = string.concat(input, ".json");
        string memory data = vm.readFile(string.concat(inputDir, chainDir, file));
        bytes memory rawConfig = data.parseRaw("");
        return abi.decode(rawConfig, (Config));
    }

    function getLambda(string memory input) internal view returns (bytes memory) {
        /// @dev Stringify the lambda function
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, input);
        string memory lambda = vm.readFile(path);
        return bytes(lambda);
    }

    function run() public {
        config = configureNetwork("manager-config");
        bytes memory lambda = getLambda("/lambdas/shipping-oracleV2.js");
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
                "initialize(address,address,uint32)",
                config.oracle,
                address(vault),
                config.gasLimit
            )
        );
        vault.setStoreManager(address(proxy));
        console.log("StoreManager address: ", address(proxy));
        FunctionsBillingRegistryInterface(0xEe9Bf52E5Ea228404bB54BCFbbDa8c21131b9039).addConsumer(393, address(proxy));
        StoreManager(address(proxy)).setLambda(lambda);
        // StoreManager(address(proxy)).setSecrets(config.secret);
        // StoreManager(address(proxy)).requestTracking(
        //     "SHIPPO_TRANSIT", "shippo", keccak256(abi.encodePacked("one")), bytes("company1")
        // );
        vm.stopBroadcast();
    }
}

//secret: 0xd9db9172cd2679e65a24b81a5bf8d513021a942d9ffc54d6ae98f9745f16762e574e53c2ef9fa2a2e58275a32a9ed4eddd6bc2936122222d9c91f548cd1290f599d5b1e0e22f2eb64c5e3142fe8a935bcdb9a69eb06c4338621e05c0ddf74c77e206a141387ff4db210d4aca41dc811fa3418c040501a76514bdd896a38f4b0e2bd8f743194cf4104dbd6438b7d54f9e0cc370acbe424c9cbe3621141ecd1d0f93
