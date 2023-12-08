// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { BaseHook } from "contracts/hooks/base/BaseHook.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";

/// @title Synchronous Base Hook
/// @notice This contract serves as the base for all synchronous hooks.
abstract contract SyncBaseHook is BaseHook {
    /// @dev Emits when a synchronous hook is executed.
    event SyncHookExecuted(address indexed hookAddress, HookResult indexed result, bytes contextData, bytes returnData);

    /// @notice Constructs the Sync Base Hook contract.
    /// @param accessControl_ The address of the access control contract.
    constructor(address accessControl_) BaseHook(accessControl_) {}

    /// @notice Executes a synchronous hook.
    /// @dev Modules utilize this function to make a synchronous call.
    /// Only callers with the HOOK_CALLER_ROLE can call this function.
    /// @param hookContext_ The context associated with hook execution.
    /// @return result The result of the hook execution.
    /// @return hookData The data returned by the hook.
    function executeSync(
        bytes calldata hookContext_
    ) external override onlyRole(AccessControl.HOOK_CALLER_ROLE) returns (HookResult result, bytes memory hookData) {
        Hook.ExecutionContext memory context = abi.decode(hookContext_, (Hook.ExecutionContext));
        _validateConfig(context.config);
        hookData = _executeSyncCall(context.config, context.params);
        result = HookResult.Completed;
        emit SyncHookExecuted(address(this), result, hookContext_, hookData);
    }

    /// @dev Executes a synchronous call. This reverts in case of any errors.
    /// @param hookConfig_ The configuration of the hook.
    /// @param hookParams_ The parameters for the hook.
    /// @return hookData The data returned by the hook.
    function _executeSyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal virtual returns (bytes memory);
}
