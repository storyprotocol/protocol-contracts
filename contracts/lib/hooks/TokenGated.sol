// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

/// @title TokenGated
/// @notice This library defines the Config and Params structs used in the TokenGatedHook.
/// @dev The Config struct contains the tokenAddress field, and the Params struct contains the tokenOwner field.
library TokenGated {
    /// @notice Defines the required configuration information for the TokenGatedHook.
    /// @dev The Config struct contains a single field: tokenAddress.
    struct Config {
        /// @notice The address of the ERC721 token contract.
        /// @dev This address is used to check if the tokenOwner owns a token of the specified ERC721 token contract.
        address tokenAddress;
    }

    /// @notice Defines the required parameter information for executing the TokenGatedHook.
    /// @dev The Params struct contains a single field: tokenOwner.
    struct Params {
        /// @notice The address of the token owner.
        /// @dev This address is checked against the tokenAddress in the Config struct to ensure the owner has a token.
        address tokenOwner;
    }
}
