// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice An enum representing the various result states of the hook.
/// @dev Pending: The hook is currently executing and has not yet completed; indicates asynchronous operation.
/// @dev Completed: The hook has completed successfully.
enum HookResult {
    Pending,
    Completed
}

/// @title IHook
/// @notice This interface defines the methods for synchronous and asynchronous hooks.
/// @dev Hooks are used to execute custom logic in response to certain events or conditions.
interface IHook {

    /// @notice Executes a synchronous hook.
    /// @param hookContext_ The context of executing a hook. It is an encoded version of Hook.ExecutionContext 
    /// @return result The result of the hook execution.
    /// @return hookData The data returned by the hook.
    function executeSync(
        bytes calldata hookContext_
    ) external returns (HookResult result, bytes memory hookData);

    /// @notice Executes an asynchronous hook.
    /// @param hookContext_ The context of executing a hook. It is an encoded version of Hook.ExecutionContext 
    /// @param callbackHandler_ The address of the callback handler.
    /// @return result The result of the hook execution.
    /// @return hookData The data returned by the hook.
    /// @return requestId The ID of the request.
    function executeAsync(
        bytes calldata hookContext_,
        address callbackHandler_
    )
        external
        returns (HookResult result, bytes memory hookData, bytes32 requestId);

    /// @notice Validates the configuration for the hook.
    /// @dev This function should be overridden in concrete Hook to provide specific validation logic.
    /// @param hookConfig_ The configuration data for the hook.
    function validateConfig(bytes calldata hookConfig_) external view;
}
