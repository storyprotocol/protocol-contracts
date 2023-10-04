// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title Royalty Policy Interface
/// @notice The Royalty policy perform concrete operations of distributing royalty.
interface IRoyaltyPolicy {

    /// @notice initialize the royalty policy for the specified IP Account
    /// @param account IP Account associated with the policy.
    /// @param data The initial data of the royalty distribution policy.
    function initPolicy(address account, bytes calldata data) external;

    /// @notice update distribute plan for the specified IP Account
    /// @param account IP Account associated with the policy.
    /// @param data The distribution plan data.
    function updateDistribution(address account, bytes calldata data) external;

    /// @notice Distribute royalty to each recipient according to royalty distribution plan for given IP Asset.
    /// @param account IP Account associated with the policy.
    /// @param token The ERC20 token for royalty.
    function distribute(address account, address token) external;
}