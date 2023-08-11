// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library LibTimeConditional {

    struct TimeConfig {
        uint112 maxTTL;
        uint112 minTTL;
        bool renewable;
        address renewer;
        uint256 endTime;
    }

}