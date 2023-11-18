// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { BaseHook } from "contracts/hooks/base/BaseHook.sol";
import { ICallbackHandler } from "contracts/interfaces/hooks/base/ICallbackHandler.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";

/// @title AsyncBaseHook
/// @notice This contract is the base contract for all asynchronous hooks.
/// @dev It provides the basic structure and functionality for asynchronous hook execution.
abstract contract AsyncBaseHook is BaseHook {
    using ERC165Checker for address;

    /// @dev requestId => callback handler
    mapping(bytes32 => ICallbackHandler) public callbackHandlers;

    /// @dev Emitted when an asynchronous hook is executed.
    event AsyncHookExecuted(
        address indexed hookAddress,
        address indexed callbackHandler,
        HookResult indexed result,
        bytes32 requestId,
        bytes contextData,
        bytes returnData
    );

    /// @dev Emitted when an asynchronous hook is called back from external service.
    event AsyncHookCalledBack(
        address indexed hookAddress,
        address indexed callbackHandler,
        bytes32 requestId,
        bytes callbackData
    );

    /// @notice Constructs the AsyncBaseHook contract.
    /// @param accessControl_ The address of the access control contract.
    /// @dev The constructor sets the access control and callback caller addresses.
    constructor(
        address accessControl_
    ) BaseHook(accessControl_) {}

    /// @notice Executes an asynchronous hook.
    /// @dev Modules would utilize the function to make an async call.
    /// Only a caller with the HOOK_CALLER_ROLE can call this function.
    /// @param hookContext_ The context of executing a hook.
    /// @param callbackHandler_ The address of the callback handler.
    /// @return result The result of the hook execution.
    /// @return hookData The data returned by the hook.
    /// @return requestId The ID of the request.
    function executeAsync(
        bytes calldata hookContext_,
        address callbackHandler_
    )
        external
        virtual
        override
        onlyRole(AccessControl.HOOK_CALLER_ROLE)
        returns (HookResult result, bytes memory hookData, bytes32 requestId)
    {
        if (callbackHandler_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        // Check if the callback handler supports the ICallbackHandler interface
        if (
            !callbackHandler_.supportsInterface(
                type(ICallbackHandler).interfaceId
            )
        ) {
            revert Errors.UnsupportedInterface("ICallbackHandler");
        }

        Hook.ExecutionContext memory context = abi.decode(
            hookContext_,
            (Hook.ExecutionContext)
        );
        _validateConfig(context.config);

        // Request an asynchronous call
        (hookData, requestId) = _requestAsyncCall(context.config, context.params);
        // Store the callback handler for the request
        callbackHandlers[requestId] = ICallbackHandler(callbackHandler_);
        // Set the result to Pending as the Hook is still running
        result = HookResult.Pending;
        // Emit the AsyncHookExecuted event
        emit AsyncHookExecuted(address(this), callbackHandler_, result, requestId, hookContext_, hookData);
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
    ) internal virtual returns (bytes memory hookData, bytes32 requestId);

    /// @dev Internal function to get the address of the callback caller.
    /// concrete hoot implementation should override the function.
    /// @param requestId_ The ID of the request.
    /// @return The address of the callback caller.
    function _callbackCaller(bytes32 requestId_) internal view virtual returns (address);

    /// @dev Internal function to handle a callback from an asynchronous call.
    /// @param requestId_ The ID of the request.
    /// @param callbackData_ The data returned by the callback.
    function _handleCallback(
        bytes32 requestId_,
        bytes memory callbackData_
    ) internal virtual {
        // Only designated callback caller can make a callback
        address caller = _callbackCaller(requestId_);
        if (msg.sender != caller) {
            revert Errors.Hook_OnlyCallbackCallerCanCallback(
                msg.sender,
                caller
            );
        }

        // Checking if a callback handler exists for the given request ID
        if (address(callbackHandlers[requestId_]) == address(0)) {
            revert Errors.Hook_InvalidAsyncRequestId(requestId_);
        }

        // Emitting an event to signal that an async hook has been called back
        emit AsyncHookCalledBack(address(this), address(callbackHandlers[requestId_]), requestId_, callbackData_);

        // Invoking the callback handler to process the returned data
        callbackHandlers[requestId_].handleHookCallback(requestId_, callbackData_);
        // Cleaning up the callback handler mapping to free up storage
        delete callbackHandlers[requestId_];
    }
}
