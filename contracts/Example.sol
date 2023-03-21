// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {FunctionsClient, Functions} from "@chainlink/src/v0.8/dev/functions/FunctionsClient.sol";

/**
 * @title Chainlink Functions example client contract implementation
 */
contract Example is FunctionsClient {
    using Functions for Functions.Request;

    uint32 public constant MAX_CALLBACK_GAS = 200_000;

    bytes32 public lastRequestId;
    bytes public lastResponse;
    bytes public lastError;
    uint32 public lastResponseLength;
    uint32 public lastErrorLength;
    bytes secret;

    error UnexpectedRequestID(bytes32 requestId);

    constructor(address oracle) FunctionsClient(oracle) {}

    function setSecret(bytes memory _secret) external {
        secret = _secret;
    }

    /**
     * @notice Send a simple request
     * @param source JavaScript source code
     * @param args List of arguments accessible from within the source code
     * @param subscriptionId Billing ID
     */
    function SendRequest(string calldata source, string[] calldata args, uint64 subscriptionId) external {
        Functions.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        req.addRemoteSecrets(secret);
        if (args.length > 0) req.addArgs(args);
        lastRequestId = sendRequest(req, subscriptionId, MAX_CALLBACK_GAS);
    }

    /**
     * @notice Store latest result/error
     * @param requestId The request ID, returned by sendRequest()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     * Either response or error parameter will be set, but never both
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }
        // Save only the first 32 bytes of reponse/error to always fit within MAX_CALLBACK_GAS
        lastResponse = response;
        lastResponseLength = uint32(response.length);
        lastError = err;
        lastErrorLength = uint32(err.length);
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32) {
        bytes32 out;
        uint256 maxLen = 32;
        if (b.length < 32) {
            maxLen = b.length;
        }
        for (uint256 i = 0; i < maxLen; i++) {
            out |= bytes32(b[i]) >> (i * 8);
        }
        return out;
    }

    function bytes32ToHexString(bytes32 input) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory result = new bytes(64);

        for (uint256 i = 0; i < 32; i++) {
            uint8 currentByte = uint8(input[i]);
            result[i * 2] = alphabet[currentByte >> 4];
            result[i * 2 + 1] = alphabet[currentByte & 0x0f];
        }

        return string(result);
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(64);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes32[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes32[i / 2] >> 4);

            bytesArray[i] = toByte(_f);
            i = i + 1;
            bytesArray[i] = toByte(_l);
        }
        return string(bytesArray);
    }

    function toByte(uint8 _uint8) public pure returns (bytes1) {
        if (_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }
}
