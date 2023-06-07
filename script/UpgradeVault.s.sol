// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Utils} from "../contracts/utils/Utils.sol";
import {Vault} from "../contracts/Vault.sol";
import {UUPSProxy} from "../contracts/proxy/UUPSProxy.sol";

contract UpgradeVaultScript is Utils {
    Vault newVersion;
    uint256 deployerPrivateKey;
    UUPSProxy proxy;

    function run() public {
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        vm.startBroadcast(deployerPrivateKey);
        deploy();
        

        vm.stopBroadcast();
    }

    function deploy() public {
        newVersion = new Vault();
        proxy = new UUPSProxy(
            address(newVersion),
            abi.encodeWithSignature(
                "initialize(address)",
                getValue("storeManager")
            )
        );
        updateDeployment(address(proxy), "vault");
    }

    function upgrade() public {
        newVersion = new Vault();
        Vault(getValue("vault")).upgradeTo(address(newVersion));
    }
}