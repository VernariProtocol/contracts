// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {StoreManager} from "../contracts/StoreManager.sol";
import {StoreFactory} from "../contracts/StoreFactory.sol";
import {Store} from "../contracts/Store.sol";
import {Vault} from "../contracts/Vault.sol";
import "../contracts/proxy/UUPSProxy.sol";
import {Example} from "../contracts/Example.sol";
import {FunctionsOracleInterface} from "@chainlink/src/v0.8/dev/interfaces/FunctionsOracleInterface.sol";

interface FunctionsBillingRegistryInterface {
    function addConsumer(uint64 subscriptionId, address consumer) external;
    function startBilling(bytes calldata data, RequestBilling calldata billing) external returns (bytes32);

    struct RequestBilling {
        // a unique subscription ID allocated by billing system,
        uint64 subscriptionId;
        // the client contract that initiated the request to the DON
        // to use the subscription it must be added as a consumer on the subscription
        address client;
        // customer specified gas limit for the fulfillment callback
        uint32 gasLimit;
        // the expected gas price used to execute the transaction
        uint256 gasPrice;
    }
}

contract NetworkForkTest is Test {
    using stdJson for string;

    StoreManager manager;
    StoreFactory factory;
    Store blueprint;
    Store store;
    address admin;
    uint256 network;
    Vault vault;
    Config config;
    UUPSProxy proxy;
    StoreManager proxyManager;
    FunctionsBillingRegistryInterface billing;
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
        string memory lambdaString = vm.readFile(path);
        return bytes(lambdaString);
    }

    // function setUp() public {
    //     network = vm.createSelectFork(vm.rpcUrl("mumbai"));
    //     admin = makeAddr("admin");
    //     manager = StoreManager(0x3A010951F54F3B05239f48aD4edF7DCB39e9f0D1);
    // }

    function setUp() public {
        lambda = getLambda("/lambdas/shipping-oracleV2.js");
        network = vm.createSelectFork(vm.rpcUrl("mumbai"));
        config = configureNetwork("manager-config");
        blueprint = new Store();
        admin = makeAddr("admin");
        vm.startPrank(0x4Fdd54a50623a7C7b5b3055700eB4872356bd5b3);
        vault = new Vault();

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
        proxyManager.setSecrets(
            hex"d9db9172cd2679e65a24b81a5bf8d513021a942d9ffc54d6ae98f9745f16762e574e53c2ef9fa2a2e58275a32a9ed4eddd6bc2936122222d9c91f548cd1290f599d5b1e0e22f2eb64c5e3142fe8a935bcdb9a69eb06c4338621e05c0ddf74c77e206a141387ff4db210d4aca41dc811fa3418c040501a76514bdd896a38f4b0e2bd8f743194cf4104dbd6438b7d54f9e0cc370acbe424c9cbe3621141ecd1d0f93"
        );
        vault.setStoreManager(address(proxyManager));
        FunctionsBillingRegistryInterface(0xEe9Bf52E5Ea228404bB54BCFbbDa8c21131b9039).addConsumer(
            393, address(proxyManager)
        );
        factorySetup();
        address a_store = factory.createStore(admin, bytes("the store"), 393, 60);
        store = Store(payable(a_store));
        proxyManager.addCompany(address(store));

        vm.stopPrank();
    }

    function factorySetup() internal {
        factory = new StoreFactory(address(blueprint), "v0.0.1", address(proxyManager));
    }

    // function testFork_managerCheckUpkeep() public {
    //     vm.prank(admin);
    //     vm.deal(admin, 0.01 ether);
    //     store.addOrder{value: 0.01 ether}(keccak256(abi.encodePacked("one")), 0.01 ether);
    //     vm.prank(admin);
    //     store.updateOrder(keccak256(abi.encodePacked("one")), "SHIPPO_DELIVERED", "shippo");
    //     vm.startPrank(0x4Fdd54a50623a7C7b5b3055700eB4872356bd5b3);
    //     vm.warp(block.timestamp + 61);
    //     (bool needed,) = proxyManager.checkUpkeep(bytes("the store"));
    //     assertTrue(needed);
    //     vm.stopPrank();
    //     vm.prank(0xeA6721aC65BCeD841B8ec3fc5fEdeA6141a0aDE4);
    //     proxyManager.performUpkeep(bytes("the store"));
    // }

    // function testFork_something() public {
    //     bytes memory data =
    //         hex"6c636f64654c6f636174696f6e00686c616e67756167650066736f75726365790364636f6e7374206261736555524c203d206068747470733a2f2f6170692e676f73686970706f2e636f6d2f747261636b732f603b0a636f6e737420747261636b696e674e756d626572203d20617267735b305d3b0a636f6e7374207368697070696e67436f6d70616e79203d20617267735b315d3b0a636f6e7374206f726465724964203d20617267735b325d3b0a636f6e73742075726c203d2060247b6261736555524c7d247b7368697070696e67436f6d70616e797d2f247b747261636b696e674e756d6265727d603b0a0a636f6e73742061706952657175657374203d2046756e6374696f6e732e6d616b654874747052657175657374287b0a202075726c3a2075726c2c0a2020686561646572733a207b0a20202020417574686f72697a6174696f6e3a206053686970706f546f6b656e20247b736563726574732e73686970706f4b65797d602c0a20207d2c0a7d293b0a0a636f6e737420726573203d20617761697420617069526571756573743b0a696620287265732e6572726f7229207b0a20207468726f77206e6577204572726f7228225368697070696e6720415049204572726f7222293b0a7d0a0a636f6e737420747261636b696e67537461747573203d207265732e646174612e747261636b696e675f7374617475732e7374617475733b0a636f6e736f6c652e6c6f6728747261636b696e67537461747573293b0a6c657420737461747573496e74203d20303b0a69662028747261636b696e67537461747573203d3d3d202244454c4956455245442229207b0a2020737461747573496e74203d20323b0a7d0a0a636f6e737420696e7465676572427566666572203d204275666665722e616c6c6f632834293b0a696e74656765724275666665722e7772697465496e743332424528737461747573496e74293b0a636f6e737420706164646564427566666572203d204275666665722e616c6c6f63283332293b0a696e74656765724275666665722e636f7079287061646465644275666665722c203332202d2034293b0a0a636f6e737420686578427566666572203d204275666665722e66726f6d286f7264657249642c202268657822293b0a636f6e737420627566203d204275666665722e636f6e636174285b7061646465644275666665722c206865784275666665725d293b0a72657475726e206275663b0a64617267739f7053484950504f5f44454c4956455245446673686970706f784032336463313131643763336164316466393830366365316538656234663535663537646261313137333339633534356537353933643166366333623032363632ff6f736563726574734c6f636174696f6e01677365637265747358a1d9db9172cd2679e65a24b81a5bf8d513021a942d9ffc54d6ae98f9745f16762e574e53c2ef9fa2a2e58275a32a9ed4eddd6bc2936122222d9c91f548cd1290f599d5b1e0e22f2eb64c5e3142fe8a935bcdb9a69eb06c4338621e05c0ddf74c77e206a141387ff4db210d4aca41dc811fa3418c040501a76514bdd896a38f4b0e2bd8f743194cf4104dbd6438b7d54f9e0cc370acbe424c9cbe3621141ecd1d0f93";
    //     vm.prank(0xeA6721aC65BCeD841B8ec3fc5fEdeA6141a0aDE4);
    //     FunctionsOracleInterface(0xeA6721aC65BCeD841B8ec3fc5fEdeA6141a0aDE4).sendRequest(393, data, 200_000);
    //     // vm.prank(0xeA6721aC65BCeD841B8ec3fc5fEdeA6141a0aDE4);
    //     // bytes32 requestId = FunctionsBillingRegistryInterface(0xEe9Bf52E5Ea228404bB54BCFbbDa8c21131b9039).startBilling(
    //     //     data,
    //     //     FunctionsBillingRegistryInterface.RequestBilling(393, address(proxyManager), config.gasLimit, tx.gasprice)
    //     // );
    // }
}
