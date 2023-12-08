// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { SyncBaseHook } from "contracts/hooks/base/SyncBaseHook.sol";
import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { MockSyncHook } from "test/foundry/mocks/MockSyncHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";

contract TestSyncBaseHook is BaseTest {
    MockSyncHook hook;

    event SyncHookExecuted(
        address indexed hookAddress,
        HookResult indexed result,
        bytes contextData,
        bytes returnData
    );

    function setUp() public override {
        super.setUp();

        vm.prank(admin);
        accessControl.grantRole(AccessControl.HOOK_CALLER_ROLE, address(this));

        hook = new MockSyncHook(address(accessControl));
    }

    function test_syncBaseHook_executeSyncValidParams() public {
        bytes memory hookParams = "0x1234";
        bytes memory hookConfig = "0x5678";
        bytes memory context = _getExecutionContext(hookConfig, hookParams);
        bytes memory expectedHookData = _getExpectedReturnData(hookConfig, hookParams);
        HookResult result;
        bytes memory hookData;

        // Execute the sync hook
        (result, hookData) = hook.executeSync(context);

        // Check the result
        assertEq(uint(result), uint(HookResult.Completed));

        // Check the hook data
        assertEq0(hookData, expectedHookData);
    }

    function test_syncBaseHook_executeSyncVerifyEvent() public {
        bytes memory hookParams = "0x1234";
        bytes memory hookConfig = "0x5678";
        bytes memory context = _getExecutionContext(hookConfig, hookParams);
        bytes memory expectedHookData = _getExpectedReturnData(hookConfig, hookParams);

        vm.expectEmit(address(hook));
        emit SyncHookExecuted(
            address(hook),
            HookResult.Completed,
            context,
            expectedHookData
        );
        // Execute the sync hook
        hook.executeSync(context);
    }

    function test_syncBaseHook_revert_NotQualifiedHookCaller() public {
        bytes memory hookParams = "0x1234";
        vm.startPrank(address(0x7777));
        // Try to handle the callback with an invalid request ID
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.MissingRole.selector,
                AccessControl.HOOK_CALLER_ROLE,
                address(0x7777)
            )
        );
        hook.executeSync(hookParams);
        vm.stopPrank();
    }

    function test_syncBaseHook_revert_executeAsyncCall() public {
        bytes memory hookParams = "0x1234";

        vm.expectRevert(Errors.Hook_UnsupportedAsyncOperation.selector);
        hook.executeAsync(hookParams, address(this));
    }

    function _getExecutionContext(bytes memory hookConfig_, bytes memory hookParams_) internal pure returns (bytes memory) {
        Hook.ExecutionContext memory context = Hook.ExecutionContext({
            config: hookConfig_,
            params: hookParams_
        });
        return abi.encode(context);
    }

    function _getExpectedReturnData(bytes memory hookConfig_, bytes memory hookParams_) internal pure returns(bytes memory) {
        return abi.encode(hookConfig_, hookParams_);
    }
}
