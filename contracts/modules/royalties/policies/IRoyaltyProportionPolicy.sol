// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./IRoyaltyPolicy.sol";

interface IRoyaltyProportionPolicy is IRoyaltyPolicy {
    struct ProportionData {
        address[] accounts;
        uint32[] percentAllocations;
    }
}