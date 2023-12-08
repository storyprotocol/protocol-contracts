// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Interface for processing token requests via clients on Polygon.
interface IPolygonTokenClient {
    function sendRequest(
        bytes32 requestId,
        address requester,
        address tokenAddress,
        address tokenOwnerAddress,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    ) external;
}
