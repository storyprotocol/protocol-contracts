// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

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
}
