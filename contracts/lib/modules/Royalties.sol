// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

/// @title Royalties Module Library
library Royalties {
    /// @notice Struct for configuring royalty allocations.
    struct ProportionData {
        address[] accounts;
        uint32[] percentAllocations;
    }
}
