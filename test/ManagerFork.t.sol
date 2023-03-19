// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {StoreManager} from "../contracts/StoreManager.sol";
import {Vault} from "../contracts/Vault.sol";
import "../contracts/proxy/UUPSProxy.sol";

contract NetworkForkTest is Test {
    using stdJson for string;

    StoreManager manager;
    address admin;
    uint256 network;
    Vault vault;
    Config config;
    UUPSProxy proxy;
    StoreManager proxyManager;

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

    function setUp() public {
        network = vm.createSelectFork(vm.rpcUrl("mumbai"));
        admin = makeAddr("admin");
        manager = StoreManager(0x3A010951F54F3B05239f48aD4edF7DCB39e9f0D1);
    }

    // function setUp() public {
    //     network = vm.createSelectFork(vm.rpcUrl("mumbai"));
    //     config = configureNetwork("manager-config");
    //     admin = makeAddr("admin");
    //     vm.startPrank(admin);
    //     vault = new Vault();

    //     StoreManager impl = new StoreManager(config.oracle);
    //     proxy = new UUPSProxy(
    //         address(impl),
    //         abi.encodeWithSignature(
    //             "initialize(address,address,uint32)",
    //             config.oracle,
    //             address(vault),
    //             300_000
    //         )
    //     );
    //     proxyManager = StoreManager(address(proxy));
    //     vault.setStoreManager(address(proxyManager));
    //     vm.stopPrank();
    // }

    function test_getPubKey() public view {
        address a = proxyManager.getOracleAddress();
        bytes memory v = proxyManager.getDONPublicKey();

        console.logBytes(v);
    }

    function testFork_managerCheckUpkeep() public {
        // manager.requestTracking(
        //     "SHIPPO_TRANSIT",
        //     "usps",
        //     0x23dc111d7c3ad1df9806ce1e8eb4f55f57dba117339c545e7593d1f6c3b02662,
        //     bytes("company1")
        // );
        manager.requestTracking("SHIPPO_TRANSIT", "shippo", keccak256(abi.encodePacked("one")), bytes("company1"));
    }
}
