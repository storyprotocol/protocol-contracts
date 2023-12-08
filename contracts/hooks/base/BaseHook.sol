// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IHook, HookResult } from "contracts/interfaces/hooks/base/IHook.sol";

/// @title Base Hook
/// @notice This contract serves as the foundation for all hook contracts.
/// @dev This contract provides authorization checks shared by all hooks, and is inherited
///      by the AsyncBaseHook and SyncBaseHook, which hook implementations should extend from.
abstract contract BaseHook is IHook, AccessControlled {
    /// @notice Creates the Base Hook contract.
    /// @param accessControl_ The address of the contract used for authorization.
    constructor(address accessControl_) AccessControlled(accessControl_) {}

    /// @notice Executes a synchronous hook.
    /// @dev By default, synchronous execution is disabled and this function reverts.
    /// Subclasses can enable synchronous execution by overriding this function.
    /// Only a caller with the HOOK_CALLER_ROLE can call this function.
    function executeSync(
        bytes calldata
    ) external virtual override onlyRole(AccessControl.HOOK_CALLER_ROLE) returns (HookResult, bytes memory) {
        revert Errors.Hook_UnsupportedSyncOperation();
    }

    /// @notice Executes an asynchronous hook.
    /// @dev By default, asynchronous execution is disabled and this function reverts.
    /// Subclasses can enable asynchronous execution by overriding this function.
    /// Only a caller with the HOOK_CALLER_ROLE can call this function.
    function executeAsync(
        bytes calldata,
        address
    ) external virtual override onlyRole(AccessControl.HOOK_CALLER_ROLE) returns (HookResult, bytes memory, bytes32) {
        revert Errors.Hook_UnsupportedAsyncOperation();
    }

    /// @notice Validates the configuration for the hook.
    /// @dev If validation fails, this function will throw.
    /// @param hookConfig_ The configuration data for the hook.
    function validateConfig(bytes calldata hookConfig_) external view override {
        _validateConfig(hookConfig_);
    }

    /// @notice Validates the configuration for the hook.
    /// @dev This function is intended to be overridden by hook implementations to provide
    ///      specialized validation logic. If validation fails, this function should throw.
    /// @param hookConfig_ The configuration data for the hook.
    function _validateConfig(bytes memory hookConfig_) internal view virtual;
}
