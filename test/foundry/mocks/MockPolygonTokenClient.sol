// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title MockPolygonTokenClient
/// @notice This contract client of Polygon Token Oracle
contract MockPolygonTokenClient {
    /// @notice Emits an event for a Polygon token balance request.
    /// @param requestId The unique ID of the request.
    /// @param requester The address of the requester.
    /// @param tokenAddress The address of the token.
    /// @param tokenOwnerAddress The address of the token owner.
    /// @param callbackAddr The address of the callback.
    /// @param callbackFunctionSignature The signature of the callback function.
    event PolygonTokenBalanceRequest(
        bytes32 indexed requestId,
        address indexed requester,
        address tokenAddress,
        address tokenOwnerAddress,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    );

    function sendRequest(
        bytes32 requestId,
        address requester,
        address tokenAddress,
        address tokenOwnerAddress,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    ) external {
        emit PolygonTokenBalanceRequest(
            requestId,
            requester,
            tokenAddress,
            tokenOwnerAddress,
            callbackAddr,
            callbackFunctionSignature
        );
    }
}
