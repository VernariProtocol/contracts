//SPDX-License-Identifier: MIT
pragma solidity <=0.8.17;

interface IStoreFactory {
    event InstanceCreated(address admin, address proxy);

    error Unauthorized();
    error InstanceAlreadyInitialized();
    error InstanceDoesNotExist();
    error ZeroAddress();

    function createStore(address admin, bytes calldata companyName, uint64 subId) external returns (address);
    function updateBeaconInstance(address newBlueprint, string calldata updatedVersion) external;
    function getInstance(address instanceOwner) external view returns (address);
    function getImplementation() external view returns (address);
    function getCurrentVersion() external view returns (string memory);
}
