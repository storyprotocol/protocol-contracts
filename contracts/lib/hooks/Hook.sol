// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
/// @title Hook
/// @notice This library defines the ExecutionContext struct used when executing hooks.
/// @dev The ExecutionContext struct contains two fields: config and params, both of type bytes.
library Hook {
    /// @notice Defines the execution context for a hook.
    /// @dev The ExecutionContext struct is used as a parameter when executing hooks.
    struct ExecutionContext {
        /// @notice The configuration data for the hook, encoded as bytes.
        /// @dev This data is used to configure the hook before execution. 
        /// The configuration is stored in the Module.
        bytes config;
        /// @notice The parameters for the hook, encoded as bytes.
        /// @dev These parameters are passed from the external caller when executing modules.
        bytes params;
    }

    function canSupportSyncCall(IHook self) internal pure returns (bool) {
        // TODO: return uint256(uint160(address(self))) & SYNC_FLAG != 0;
        return true;
    }

    function canSupportAsyncCall(IHook self) internal pure returns (bool) {
        // TODO:  return uint256(uint160(address(self))) & ASYNC_FLAG != 0;
        return true;
    }
}
