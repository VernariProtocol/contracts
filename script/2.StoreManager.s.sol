// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {StoreManager} from "../contracts/StoreManager.sol";
import {UUPSProxy} from "../contracts/proxy/UUPSProxy.sol";
import {Vault} from "../contracts/Vault.sol";
import {Utils} from "../contracts/utils/Utils.sol";

interface FunctionsBillingRegistryInterface {
    function addConsumer(uint64 subscriptionId, address consumer) external;
}

contract StoreManagerScript is Utils {
    StoreManager impl;
    Vault vaultImpl;
    UUPSProxy proxy;
    UUPSProxy vaultProxy;
    uint256 deployerPrivateKey;

    function getLambda(string memory input) internal view returns (bytes memory) {
        /// @dev Stringify the lambda function
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, input);
        string memory lambda = vm.readFile(path);
        return bytes(lambda);
    }

    function run() public {
        bytes memory lambda = getLambda("/lambdas/shipping-oracleV2.js");
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }

        vm.startBroadcast(deployerPrivateKey);
        address oracle = getValue("oracle");
        impl = new StoreManager(oracle);
        vaultImpl = new Vault();
        vaultProxy = new UUPSProxy(
            address(vaultImpl),
            abi.encodeWithSignature(
                "initialize(address)",
                address(0)
            )
        );
        updateDeployment(address(vaultProxy), "vault");
        proxy = new UUPSProxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address,address,uint32)",
                oracle,
                address(vaultProxy),
                200_000
            )
        );
        updateDeployment(address(proxy), "storeManager");
        Vault(address(vaultProxy)).setStoreManager(address(proxy));
        FunctionsBillingRegistryInterface(0xEe9Bf52E5Ea228404bB54BCFbbDa8c21131b9039).addConsumer(393, address(proxy));
        StoreManager(address(proxy)).setLambda(lambda);
        // StoreManager(address(proxy)).setSecrets(config.secret);
        // StoreManager(address(proxy)).requestTracking(
        //     "SHIPPO_TRANSIT", "shippo", keccak256(abi.encodePacked("one")), bytes("company1")
        // );
        vm.stopBroadcast();
    }
}

//secret: 0x9ca278b7c7d17d6af5a3e49fa0b76d690322720c9e75803da8dbe630eefc6fe8d30e1033fbbb682b4c639a1878b4ff8a223ac1652b28d1a0a8b600928cfc2a1ac6b24e82ca99f9b5db1b8168f760e23de8f163fa1d590448b01b1b7faeb262b107b42353112fa27fa5069dddfc1a4b7a36a1c64c08dc7029b076b0b32ec348e9d2425f92856ff334757e26699a59fa98b936fedec6179804aca50debf87694839f
//  secretsURLs: ["https://gist.github.com/AnonJon/22b0a97dca2c34479e2eda1fba92ceb9/raw/"],
//   // Default offchain secrets object used by the `functions-build-offchain-secrets` command
//   globalOffchainSecrets: { shippoKey: "shippo_test_5de1485867e4d855bb88b921b51e2eea65479053" },
// source: fs.readFileSync("./shipping-oracle.js").toString(),
//   walletPrivateKey: process.env["PRIVATE_KEY"],
//   // args can be accessed within the source code with `args[index]` (ie: args[0])
//   args: ["SHIPPO_TRANSIT", "shippo", "23dc111d7c3ad1df9806ce1e8eb4f55f57dba117339c545e7593d1f6c3b02662"],
//   // expected type of the returned value
//   expectedReturnType: ReturnType.string,