// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

library LibDuration {

    error NotRenewable();
    error CallerNotRenewer();
    error ZeroTTL();
    error InvalidStartTime();

    struct TimeConfig {
        uint64 ttl;
        uint64 startTime;
        address renewer;
    }

    function isActive(TimeConfig memory self) internal view returns (bool) {
        return self.startTime >= block.timestamp && self.startTime + self.ttl < block.timestamp;
    }

    function isRenewable(TimeConfig memory self) internal pure returns (bool) {
        return self.renewer != address(0);
    }

    function renew(TimeConfig memory self, uint64 ttl) view internal {
        if (!isRenewable(self)) revert NotRenewable();
        if (msg.sender != self.renewer) revert CallerNotRenewer();
        if (ttl == 0) revert ZeroTTL();
        self.ttl = ttl;
        self.startTime = uint64(block.timestamp);
    }

    function createRunningTimeConfig(uint64 ttl, address renewer) internal view returns (TimeConfig memory) {
        if (ttl == 0) revert ZeroTTL();
        return TimeConfig({
            ttl: ttl,
            startTime: uint64(block.timestamp),
            renewer: renewer
        });
    }

    function createStoppedTimeConfig(uint64 ttl, address renewer) internal pure returns (TimeConfig memory) {
        if (ttl == 0) revert ZeroTTL();
        return TimeConfig({
            ttl: ttl,
            startTime: 0,
            renewer: renewer
        });
    }
}