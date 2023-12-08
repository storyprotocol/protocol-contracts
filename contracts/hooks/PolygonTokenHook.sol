// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AsyncBaseHook } from "contracts/hooks/base/AsyncBaseHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IPolygonTokenClient } from "contracts/interfaces/utils/IPolygonTokenClient.sol";
import { PolygonToken } from "contracts/lib/hooks/PolygonToken.sol";

/// @title Polygon Token Hooks Contract
/// @notice Asynchronous hook used for verifying token balances on Polygon.
contract PolygonTokenHook is AsyncBaseHook {
    /// @notice The address that is allowed to call the callback function.
    address private immutable CALLBACK_CALLER;

    /// @notice The address of the Polygon client used for call fulfillment.
    address public immutable ORACLE_CLIENT;

    /// @notice A counter used to generate unique request IDs for each token request.
    uint256 private nonce;

    /// @notice A mapping that links each request ID to a PolygonTokenRequest struct.
    mapping(bytes32 => PolygonTokenRequest) private requestIdToRequest;

    /// @notice Stores information rlated to a async Polygon token balance request.
    struct PolygonTokenRequest {
        address requester; // Address of the requestor.
        address tokenAddress; // Address of the Polygon token whose balance is being queried for.
        address tokenOwnerAddress; // Address of the owner of the Polygon token.
        uint256 balanceThreshold; // The target token balance necessary for successful fulfillment.
        bool isRequestCompleted; // Whether the request was completed or not.
        bool exists; // Whether the request exists.
    }

    /// @notice Initializes the Polygon Token Hook contract.
    /// @param accessControl_ The address of the contract used for authorization.
    /// @param oracleClient_ The address of the oracle client querying for Polygon Token info.
    /// @param callbackCaller_ The address of the callback caller contract.
    constructor(address accessControl_, address oracleClient_, address callbackCaller_) AsyncBaseHook(accessControl_) {
        if (callbackCaller_ == address(0)) revert Errors.ZeroAddress();
        if (oracleClient_ == address(0)) revert Errors.ZeroAddress();
        CALLBACK_CALLER = callbackCaller_;
        ORACLE_CLIENT = oracleClient_;
    }

    /// @notice Handles the callback of a token request.
    /// @param requestId The unique ID of the request.
    /// @param balance The balance of the token.
    /// @dev This function checks if the request exists and verifies th token balance against the configured balance
    ///      threshold. If the balance is less than the threshold, an error message is set. Otherwise, the callback
    ///      is marked as successful via `isPassed=true`, and the request is deleted, after which the `handleCallback`
    ///      function is called with the encoding `abi.encode(isPassed, errorMessage)`.
    function handleCallback(bytes32 requestId, uint256 balance) external {
        bool isPassed = false;
        string memory errorMessage = "";
        if (!requestIdToRequest[requestId].exists) {
            revert Errors.Hook_RequestedNotFound();
        }
        if (balance < requestIdToRequest[requestId].balanceThreshold) {
            errorMessage = "Balance of Token is not enough";
        } else {
            isPassed = true;
        }
        delete requestIdToRequest[requestId];
        _handleCallback(requestId, abi.encode(isPassed, errorMessage));
    }

    /// @notice Validates the configuration for the async hook.
    /// @dev Validates whether the configured token address and balance threshold are valid.
    ///      This function reverts when a zero token address or a zero balance threshold is configured.
    /// @param hookConfig_ The configuration data for the hook, encoded as a bytes array.
    function _validateConfig(bytes memory hookConfig_) internal pure override {
        PolygonToken.Config memory config = abi.decode(hookConfig_, (PolygonToken.Config));
        if (config.tokenAddress == address(0)) {
            revert Errors.Hook_InvalidHookConfig("tokenAddress is 0");
        }
        if (config.balanceThreshold == 0) {
            revert Errors.Hook_InvalidHookConfig("balanceThreshold is 0");
        }
    }

    /// @dev Internal function for requesting an async call meant for implementations
    ///      to override. This function should revert in case of any errors.
    /// @param hookConfig_ The configuration of the hook.
    /// @param hookParams_ The parameters for the hook.
    /// @return hookData The data returned by the hook.
    /// @return requestId The id of the request.
    function _requestAsyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal override returns (bytes memory hookData, bytes32 requestId) {
        PolygonToken.Config memory config = abi.decode(hookConfig_, (PolygonToken.Config));
        PolygonToken.Params memory params = abi.decode(hookParams_, (PolygonToken.Params));
        requestId = keccak256(abi.encodePacked(this, nonce++));
        hookData = "";

        requestIdToRequest[requestId] = PolygonTokenRequest({
            requester: msg.sender,
            tokenAddress: config.tokenAddress,
            tokenOwnerAddress: params.tokenOwnerAddress,
            balanceThreshold: config.balanceThreshold,
            isRequestCompleted: false,
            exists: true
        });

        IPolygonTokenClient(ORACLE_CLIENT).sendRequest(
            requestId,
            msg.sender,
            config.tokenAddress,
            params.tokenOwnerAddress,
            address(this),
            this.handleCallback.selector
        );
    }

    /// @notice Returns the address of the callback caller.
    /// @return The address of the caller of the callback.
    function _callbackCaller(bytes32) internal view override returns (address) {
        return CALLBACK_CALLER;
    }
}
