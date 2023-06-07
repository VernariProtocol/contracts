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

        vm.stopBroadcast();
    }
}
