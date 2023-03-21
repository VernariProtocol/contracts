// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {StoreManager} from "../contracts/StoreManager.sol";
import {Vault} from "../contracts/Vault.sol";
import "../contracts/proxy/UUPSProxy.sol";
import {Example} from "../contracts/Example.sol";

interface FunctionsBillingRegistryInterface {
    function addConsumer(uint64 subscriptionId, address consumer) external;
}

contract NetworkForkTest is Test {
    using stdJson for string;

    StoreManager manager;
    address admin;
    uint256 network;
    Vault vault;
    Config config;
    UUPSProxy proxy;
    StoreManager proxyManager;
    FunctionsBillingRegistryInterface billing;
    Example example;
    bytes lambda;

    struct Config {
        uint32 gasLimit;
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

    function getLambda(string memory input) internal view returns (bytes memory) {
        /// @dev Stringify the lambda function
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, input);
        string memory lambda = vm.readFile(path);
        return bytes(lambda);
    }

    // function setUp() public {
    //     network = vm.createSelectFork(vm.rpcUrl("mumbai"));
    //     admin = makeAddr("admin");
    //     manager = StoreManager(0x3A010951F54F3B05239f48aD4edF7DCB39e9f0D1);
    // }

    function setUp() public {
        lambda = getLambda("/lambdas/shipping-oracle.js");
        network = vm.createSelectFork(vm.rpcUrl("mumbai"));
        config = configureNetwork("manager-config");
        admin = makeAddr("admin");
        vm.startPrank(0x4Fdd54a50623a7C7b5b3055700eB4872356bd5b3);
        vault = new Vault();
        example = new Example(config.oracle);

        StoreManager impl = new StoreManager(config.oracle);
        proxy = new UUPSProxy(
            address(impl),
            abi.encodeWithSignature(
                "initialize(address,address,uint32)",
                config.oracle,
                address(vault),
                200_000
            )
        );
        proxyManager = StoreManager(address(proxy));
        proxyManager.setLambda(lambda);
        vault.setStoreManager(address(proxyManager));
        FunctionsBillingRegistryInterface(0xEe9Bf52E5Ea228404bB54BCFbbDa8c21131b9039).addConsumer(393, address(example));
        vm.stopPrank();
    }

    function test_getPubKey() public view {
        address a = proxyManager.getOracleAddress();
        bytes memory v = proxyManager.getDONPublicKey();

        console.logBytes(v);
    }

    // function testFork_managerCheckUpkeep() public {
    //     vm.startPrank(0x4Fdd54a50623a7C7b5b3055700eB4872356bd5b3);
    //     proxyManager.getOracleAddress();
    //     // proxyManager.requestTracking("SHIPPO_TRANSIT", "shippo", keccak256(abi.encodePacked("one")), bytes("company1"));
    //     example.SendRequest(string(lambda), "", new string[](0), 393);
    // }

    function test_bytes32ToString() public {
        bytes32 x = keccak256(abi.encodePacked("one"));
        string memory s = example.bytes32ToHexString(x);
        console.log(s);
    }
}
