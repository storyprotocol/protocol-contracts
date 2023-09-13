// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IRoyaltyPolicy.sol";

/// @title Proportion Royalty Policy Interface
/// @notice The Proportion Royalty policy is split royalty by percentage.
interface IRoyaltyProportionPolicy is IRoyaltyPolicy {
   /// @notice Percentage proportion
    struct ProportionData {
        address[] accounts;
        uint32[] percentAllocations;
    }
}