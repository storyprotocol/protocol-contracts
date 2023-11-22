// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Royalty Policy Interface
/// @notice The Royalty policy perform concrete operations of distributing royalty.
interface IRoyaltyPolicy {

    /// @notice initialize the royalty policy for the specified IP Account
    /// @param account_ IP Account associated with the policy.
    /// @param data_ The initial data of the royalty distribution policy.
    function initPolicy(address account_, bytes calldata data_) external;

    /// @notice update distribute plan for the specified IP Account
    /// @param account_ IP Account associated with the policy.
    /// @param data_ The distribution plan data.
    function updateDistribution(address account_, bytes calldata data_) external;

    /// @notice Distribute royalty to each recipient according to royalty distribution plan for given IP Asset.
    /// @param account_ IP Account associated with the policy.
    /// @param token_ The ERC20 token for royalty.
    function distribute(address account_, address token_) external;
}
