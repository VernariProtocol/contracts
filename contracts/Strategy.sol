// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

contract Strategy {
    bytes internal strategyName;
    mapping(address => address) internal assetToContract;

    constructor(string memory name) {
        strategyName = bytes(name);
    }

    function name() public view returns (string memory) {
        return string(strategyName);
    }
}
