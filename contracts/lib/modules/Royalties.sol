// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title Royalties Module Library
library Royalties {

   /// @notice Struct for configuring royalty allocations.
    struct ProportionData {
        address[] accounts;
        uint32[] percentAllocations;
    }

}
