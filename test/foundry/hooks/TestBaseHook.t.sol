// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { MockBaseHook } from "test/foundry/mocks/MockBaseHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";


contract TestBaseHook is BaseTest {
    MockBaseHook hook;

    function setUp() public override {
        super.setUp();

        vm.prank(admin);
        accessControl.grantRole(AccessControl.HOOK_CALLER_ROLE, address(this));

        hook = new MockBaseHook(address(accessControl));
    }

    function test_baseHook_validateGoodConfig() public view {
        hook.validateConfig(abi.encode("GoodConfig"));
    }

    function test_baseHook_revert_NotQualifiedSyncHookCaller() public {
        bytes memory hooksParams = "0x1234";
        vm.startPrank(address(0x7777));
        // Try to handle the callback with an invalid request ID
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.MissingRole.selector,
                AccessControl.HOOK_CALLER_ROLE,
                address(0x7777)
            )
        );
        hook.executeSync(hooksParams);
        vm.stopPrank();
    }

    function test_baseHook_revert_NotQualifiedAsyncHookCaller() public {
        bytes memory hooksParams = "0x1234";
        vm.startPrank(address(0x7777));
        // Try to handle the callback with an invalid request ID
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.MissingRole.selector,
                AccessControl.HOOK_CALLER_ROLE,
                address(0x7777)
            )
        );
        hook.executeAsync(hooksParams, address(this));
        vm.stopPrank();
    }

    function test_baseHook_revert_executeSyncCall() public {
        bytes memory hooksParams = "0x1234";

        vm.expectRevert(Errors.Hook_UnsupportedSyncOperation.selector);
        hook.executeSync(hooksParams);
    }

    function test_baseHook_revert_executeAsyncCall() public {
        bytes memory hooksParams = "0x1234";

        vm.expectRevert(Errors.Hook_UnsupportedAsyncOperation.selector);
        hook.executeAsync(hooksParams, address(this));
    }

    function test_baseHook_revert_invalidConfig() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        hook.validateConfig(abi.encode("ERROR"));
    }

}
