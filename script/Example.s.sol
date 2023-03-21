// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Example} from "../contracts/Example.sol";

interface FunctionsBillingRegistryInterface {
    function addConsumer(uint64 subscriptionId, address consumer) external;
}

contract ExampleScript is Script {
    Example example;
    address mumbaiFunctionsOracle = 0x6199175d137B791B7AB06C3452aa6acc3519b254;
    address mumbaiBillingRegistry = 0xEe9Bf52E5Ea228404bB54BCFbbDa8c21131b9039;
    uint64 subID = 393;
    string lambda;
    uint32 gasLimit = 200000; // max
    uint256 deployerPrivateKey;

    /**
     * @dev Deploy the FunctionsConsumer contract and create a subscription
     *      on the billing registry. Top up the billing registry with 0.5 LINK.
     *     Add the consumer to the subscription.
     */
    function setUp() public {
        /// @dev Stringify the lambda function
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/lambdas/shipping-oracleV2.js");
        lambda = vm.readFile(path);
    }

    function run() public {
        if (block.chainid == 31337) {
            deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        } else {
            deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        vm.startBroadcast(deployerPrivateKey);
        // example = new Example(0xeA6721aC65BCeD841B8ec3fc5fEdeA6141a0aDE4);
        // FunctionsBillingRegistryInterface(0xEe9Bf52E5Ea228404bB54BCFbbDa8c21131b9039).addConsumer(393, address(example));
        tracking();
    }

    function tracking() public {
        example = Example(0xAdD19D1c851346d92716FF4b86043d10e6AE1b5a);
        string[3] memory setter =
            ["SHIPPO_TRANSIT", "shippo", "23dc111d7c3ad1df9806ce1e8eb4f55f57dba117339c545e7593d1f6c3b02662"];
        string[] memory args = new string[](setter.length);
        for (uint256 i = 0; i < setter.length; i++) {
            args[i] = setter[i];
        }
        example.SendRequest(lambda, args, 393);
    }
}
