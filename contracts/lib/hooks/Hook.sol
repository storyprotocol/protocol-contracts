// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";

/// @title Hooks Library
/// @notice This library defines the ExecutionContext struct used when executing hooks.
/// @dev The ExecutionContext struct contains two fields: config and params, both of type bytes.
library Hook {
    uint256 internal constant SYNC_FLAG = 1 << 159;
    uint256 internal constant ASYNC_FLAG = 1 << 158;
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

    /// @notice Checks if the hook can support synchronous calls.
    /// @dev This function checks if the first bit of the hook address is set to 1,
    ///      indicating that the hook can support synchronous calls.
    /// @param self_ The hook to check.
    /// @return A boolean indicating if the hook can support synchronous calls.
    function canSupportSyncCall(IHook self_) internal pure returns (bool) {
        return uint256(uint160(address(self_))) & SYNC_FLAG != 0;
    }

    /// @notice Checks if the hook can support asynchronous calls.
    /// @dev This function checks if the second bit of the hook address is set to 1,
    ///      indicating that the hook can support asynchronous calls.
    /// @param self_ The hook to check.
    /// @return A boolean indicating if the hook can support asynchronous calls.
    function canSupportAsyncCall(IHook self_) internal pure returns (bool) {
        return uint256(uint160(address(self_))) & ASYNC_FLAG != 0;
    }
}
