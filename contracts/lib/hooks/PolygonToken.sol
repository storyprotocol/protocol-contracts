// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title TokenGated
/// @notice This library defines the Config and Params structs used in the TokenGatedHook.
/// @dev The Config struct contains the tokenAddress field, and the Params struct contains the tokenOwner field.
library PolygonToken {
    /// @notice Defines the required configuration information for the TokenGatedHook.
    /// @dev The Config struct contains a single field: tokenAddress.
    struct Config {
        /// @notice The threshold of number of users who follow this user.
        address tokenAddress;
        /// @notice The threshold of number of lists that include this user.
        uint256 balanceThreshold;
    }

    /// @notice Defines the required parameter information for executing the TokenGatedHook.
    /// @dev The Params struct contains a single field: tokenOwner.
    struct Params {
        /// @notice The address of the token owner.
        /// @dev This address is checked against the tokenAddress in the Config struct to ensure the owner has a token.
        address tokenOwnerAddress;
    }
}
