// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { BaseHook } from "contracts/hooks/base/BaseHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { ICallbackHandler } from "contracts/interfaces/hooks/base/ICallbackHandler.sol";

/// @title Asynchronous Base Hook
/// @notice This contract serves as the base functionality for all asynchronous hooks.
abstract contract AsyncBaseHook is BaseHook {
    using ERC165Checker for address;

    /// @dev Maps async hook request ids to callback handlers.
    mapping(bytes32 => ICallbackHandler) public callbackHandlers;

    /// @notice This event emits when an async hook is executed.
    /// @param hookAddress Address of the executed hook.
    /// @param callbackHandler The address of the handler of the callback.
    /// @param result State of the hook (either pending or complete).
    /// @param contextData Additional contextual data related to the execution.
    /// @param returnData Data returned by the hook.
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
    constructor(address accessControl_) BaseHook(accessControl_) {}

    /// @notice Executes an asynchronous hook.
    /// @dev Modules utilize this function to make asynchronous calls.
    ///      Only callers with the HOOK_CALLER_ROLE can call this function.
    /// @param hookContext_ The context associated with hook execution.
    /// @param callbackHandler_ The address of the callback handler.
    /// @return result The result of the hook execution.
    /// @return hookData The data returned by the hook.
    /// @return requestId The id of the async request.
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
        if (!callbackHandler_.supportsInterface(type(ICallbackHandler).interfaceId)) {
            revert Errors.UnsupportedInterface("ICallbackHandler");
        }

        Hook.ExecutionContext memory context = abi.decode(hookContext_, (Hook.ExecutionContext));
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

    /// @dev Internal function to request an asynchronous call, intended to be overridden
    ///      by implementations. This function should revert in case of any errors.
    /// @param hookConfig_ The configuration of the hook.
    /// @param hookParams_ The parameters for the hook.
    /// @return hookData The data returned by the hook.
    /// @return requestId The id of the request.
    function _requestAsyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal virtual returns (bytes memory hookData, bytes32 requestId);

    /// @dev Internal function to get the address of the callback caller.
    /// @param requestId_ The id of the request.
    /// @return The address of the callback caller.
    function _callbackCaller(bytes32 requestId_) internal view virtual returns (address);

    /// @dev Internal function to handle a callback from an asynchronous call.
    /// @param requestId_ The id of the request.
    /// @param callbackData_ The data returned by the callback.
    function _handleCallback(bytes32 requestId_, bytes memory callbackData_) internal virtual {
        // Only designated callback caller can make a callback
        address caller = _callbackCaller(requestId_);
        if (msg.sender != caller) {
            revert Errors.Hook_OnlyCallbackCallerCanCallback(msg.sender, caller);
        }

        // Check if a callback handler exists for the given request id
        if (address(callbackHandlers[requestId_]) == address(0)) {
            revert Errors.Hook_InvalidAsyncRequestId(requestId_);
        }

        // Emit an event to signal that an async hook has been called back
        emit AsyncHookCalledBack(address(this), address(callbackHandlers[requestId_]), requestId_, callbackData_);

        // Invokethe callback handler to process the returned data
        callbackHandlers[requestId_].handleHookCallback(requestId_, callbackData_);
        // Clean up the callback handler mapping to free up storage
        delete callbackHandlers[requestId_];
    }
}
