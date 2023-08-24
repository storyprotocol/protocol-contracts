// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library LibTimeConditional {

    struct TimeConfig {
        bool renewable;
        address renewer;
        uint256 endTime;
    }

    function isTimeExpired(TimeConfig memory self) internal view returns (bool) {
        return self.endTime < block.timestamp;
    }

}