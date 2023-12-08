// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IHook, HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";

/// @title BaseHook
/// @notice This contract serves as the foundation for all hook contracts.
/// @dev It provides the authorization check shared by all hooks. AsyncBaseHook and SyncBaseHook inherit from BaseHook.
/// Concrete hooks usually inherit from AsyncBaseHook or SyncBaseHook, not directly from BaseHook.
abstract contract BaseHook is IHook, AccessControlled {
    /// @notice Constructs the BaseHook contract.
    /// @param accessControl_ The address of the access control contract.
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
    /// @dev This function calls the internal _validateConfig function with the provided configuration data.
    /// If the validation fails, it will revert with an error.
    /// @param hookConfig_ The configuration data for the hook.
    function validateConfig(bytes calldata hookConfig_) external view override {
        _validateConfig(hookConfig_);
    }

    /// @notice Validates the configuration for the hook.
    /// @dev This function should be overridden by concrete hook to provide specific validation logic.
    /// If the validation fails, it will revert with an error.
    /// @param hookConfig_ The configuration data for the hook.
    function _validateConfig(bytes memory hookConfig_) internal view virtual;
}
