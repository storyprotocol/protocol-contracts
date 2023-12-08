/* solhint-disable contract-name-camelcase, func-name-mixedcase, var-name-mixedcase */
// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { LibDuration } from "contracts/utils/LibDuration.sol";

contract LibDurationHarness {
    LibDuration.TimeConfig internal timeConfig;

    constructor() {
        timeConfig = LibDuration.TimeConfig({
            ttl: uint64(block.timestamp + 10_000),
            startTime: uint64(block.timestamp),
            renewer: address(0xb0b)
        });
    }

    function isActive() external view returns (bool) {
        return LibDuration.isActive(timeConfig);
    }

    function renew(uint64 ttl_) external view {
        LibDuration.renew(timeConfig, ttl_);
    }

    function createRunningTimeConfig(
        uint64 ttl_,
        address renewer_
    ) external view returns (LibDuration.TimeConfig memory) {
        return LibDuration.createRunningTimeConfig(ttl_, renewer_);
    }

    function isRenewable() external view returns (bool) {
        return LibDuration.isRenewable(timeConfig);
    }

    function createStoppedTimeConfig(
        uint64 ttl_,
        address renewer_
    ) external pure returns (LibDuration.TimeConfig memory) {
        return LibDuration.createStoppedTimeConfig(ttl_, renewer_);
    }

    function setTimeConfig() external {
        timeConfig = LibDuration.TimeConfig({
            ttl: 0,
            startTime: 0,
            renewer: address(0)
        });
    }

    function ttl() external view returns (uint64) {
        return timeConfig.ttl;
    }

    function startTime() external view returns (uint64) {
        return timeConfig.startTime;
    }

    function renewer() external view returns (address) {
        return timeConfig.renewer;
    }
}

contract LibDurationTest is Test {
    LibDurationHarness internal harness;

    function setUp() public {
        harness = new LibDurationHarness();
    }

    function test_libDuration_isActive() public {
        harness.createRunningTimeConfig(100, msg.sender);
        harness.setTimeConfig();
        assertEq(harness.isActive(), false);
    }

    function test_libDuration_renew() public {
        harness.createRunningTimeConfig(100, msg.sender);
        harness.setTimeConfig();
				vm.expectRevert(Errors.LibDuration_NotRenewable.selector);
        harness.renew(200);
    }

    function test_libDuration_createRunningTimeConfig() public {
        harness.createRunningTimeConfig(100, msg.sender);
        assertEq(harness.ttl(), 10_001); // 10_000 + 1 (next time)
        assertEq(harness.startTime(), block.timestamp);
        assertEq(harness.renewer(), address(0xb0b));
    }

    function test_libDuration_isRenewable() public {
        harness.createRunningTimeConfig(100, msg.sender);
        harness.setTimeConfig();
        assertEq(harness.isRenewable(), false);
    }

    function test_libDuration_createStoppedTimeConfig() public {
        LibDuration.TimeConfig memory config = LibDuration
            .createStoppedTimeConfig(100, msg.sender);
        assertEq(config.ttl, 100);
        assertEq(config.startTime, 0);
        assertEq(config.renewer, address(msg.sender));
    }
}
