// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PolygonToken
 * @dev This library is used for managing Polygon tokens.
 */
library PolygonToken {
    /// @notice This is the configuration for the Polygon token.
    /// @dev It includes the token address and the balance threshold.
    struct Config {
        /// @notice The address of the Polygon token.
        address tokenAddress;
        /// @notice The balance threshold for the Polygon token.
        uint256 balanceThreshold;
    }

    /// @notice This is the parameters for the Polygon token.
    /// @dev It includes the token owner address.
    struct Params {
        /// @notice The address of the Polygon token owner.
        address tokenOwnerAddress;
    }
}
