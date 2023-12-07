// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { AsyncBaseHook } from "contracts/hooks/base/AsyncBaseHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { PolygonToken } from "contracts/lib/hooks/PolygonToken.sol";

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

/// @title PolygonTokenHook
/// @notice This is asynchronous hook used to verify a user owning specific Polygon tokens.
contract PolygonTokenHook is AsyncBaseHook {
    /// @notice The address that is allowed to call the callback function.
    /// @dev This address is set during contract deployment and cannot be changed afterwards.
    address private immutable CALLBACK_CALLER;

    address public immutable ORACLE_CLIENT;

    /// @notice A counter used to generate unique request IDs for each token request.
    uint256 private nonce;

    /// @notice A mapping that links each request ID to a PolygonTokenRequest struct.
    mapping(bytes32 => PolygonTokenRequest) private requestIdToRequest;

    /// @notice A struct used to store information about a token request.
    /// @dev It includes the requester's address, the token's address, the token owner's address, a balance threshold,
    ///      and two boolean flags to indicate whether the request is completed and whether it exists.
    struct PolygonTokenRequest {
        address requester;
        address tokenAddress;
        address tokenOwnerAddress;
        uint256 balanceThreshold;
        bool isRequestCompleted;
        bool exists;
    }

    /// @notice Initializes the contract during deployment.
    /// @param accessControl_ The address of the access control contract.
    /// @param oracleClient_ The address of the oracle client contract for access Polygon Token info.
    /// @param callbackCaller_ The address of the callback caller contract.
    constructor(
        address accessControl_,
        address oracleClient_,
        address callbackCaller_
    ) AsyncBaseHook(accessControl_) {
        if (callbackCaller_ == address(0)) revert Errors.ZeroAddress();
        if (oracleClient_ == address(0)) revert Errors.ZeroAddress();
        CALLBACK_CALLER = callbackCaller_;
        ORACLE_CLIENT = oracleClient_;
    }

    /// @notice Handles the callback of a token request.
    /// @param requestId The unique ID of the request.
    /// @param balance The balance of the token.
    /// @dev This function checks if the request exists and verifies the token balance against the balance threshold.
    /// If the balance is less than the threshold, it sets an error message. Otherwise, it sets the isPassed flag to true.
    /// It then deletes the request from the requestIdToRequest mapping.
    /// Finally, it calls the _handleCallback() function, passing the requestId and the encoded isPassed flag and errorMessage.
    /// The encoding is done using abi.encode(isPassed, errorMessage).
    function handleCallback(bytes32 requestId, uint256 balance) external {
        bool isPassed = false;
        string memory errorMessage = "";
        require(requestIdToRequest[requestId].exists, "Request not found");
        if (balance < requestIdToRequest[requestId].balanceThreshold) {
            errorMessage = "Balance of Token is not enough";
        } else {
            isPassed = true;
        }
        delete requestIdToRequest[requestId];
        _handleCallback(requestId, abi.encode(isPassed, errorMessage));
    }

    /// @notice Validates the configuration for the hook.
    /// @dev This function checks if the tokenAddress and balanceThreshold in the configuration are valid.
    ///      It reverts if the tokenAddress is the zero address or if the balanceThreshold is zero.
    /// @param hookConfig_ The configuration data for the hook, encoded as bytes.
    function _validateConfig(bytes memory hookConfig_) internal pure override {
        PolygonToken.Config memory config = abi.decode(
            hookConfig_,
            (PolygonToken.Config)
        );
        if (config.tokenAddress == address(0)) {
            revert Errors.Hook_InvalidHookConfig("tokenAddress is 0");
        }
        if (config.balanceThreshold == 0) {
            revert Errors.Hook_InvalidHookConfig("balanceThreshold is 0");
        }
    }

    /// @dev Internal function to request an asynchronous call,
    /// concrete hoot implementation should override the function.
    /// The function should revert in case of error.
    /// @param hookConfig_ The configuration of the hook.
    /// @param hookParams_ The parameters for the hook.
    /// @return hookData The data returned by the hook.
    /// @return requestId The ID of the request.
    function _requestAsyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal override returns (bytes memory hookData, bytes32 requestId) {
        PolygonToken.Config memory config = abi.decode(
            hookConfig_,
            (PolygonToken.Config)
        );
        PolygonToken.Params memory params = abi.decode(
            hookParams_,
            (PolygonToken.Params)
        );
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
    /// @return The address of the callback caller.
    function _callbackCaller(bytes32) internal view override returns (address) {
        return CALLBACK_CALLER;
    }
}
