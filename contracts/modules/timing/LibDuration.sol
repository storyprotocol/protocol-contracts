// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";

library LibDuration {

    struct TimeConfig {
        uint64 ttl;
        uint64 startTime;
        address renewer;
    }

    uint64 public constant START_TIME_NOT_SET = uint64(0);

    function isActive(TimeConfig memory self_) internal view returns (bool) {
        return self_.startTime != START_TIME_NOT_SET && block.timestamp >= self_.startTime && block.timestamp < self_.startTime + self_.ttl;
    }

    function isRenewable(TimeConfig memory self_) internal pure returns (bool) {
        return self_.renewer != address(0);
    }

    function renew(TimeConfig memory self_, uint64 ttl_) view internal {
        if (!isRenewable(self_)) revert Errors.LibDuration_NotRenewable();
        if (msg.sender != self_.renewer) revert Errors.LibDuration_CallerNotRenewer();
        if (ttl_ == 0) revert Errors.LibDuration_ZeroTTL();
        self_.ttl = ttl_;
        self_.startTime = uint64(block.timestamp);
    }

    function createRunningTimeConfig(uint64 ttl_, address renewer_) internal view returns (TimeConfig memory) {
        if (ttl_ == 0) revert Errors.LibDuration_ZeroTTL();
        return TimeConfig({
            ttl: ttl_,
            startTime: uint64(block.timestamp),
            renewer: renewer_
        });
    }

    function createStoppedTimeConfig(uint64 ttl_, address renewer_) internal pure returns (TimeConfig memory) {
        if (ttl_ == 0) revert Errors.LibDuration_ZeroTTL();
        return TimeConfig({
            ttl: ttl_,
            startTime: 0,
            renewer: renewer_
        });
    }
}
