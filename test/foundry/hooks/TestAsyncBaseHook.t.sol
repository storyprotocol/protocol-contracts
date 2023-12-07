// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { AsyncBaseHook } from "contracts/hooks/base/AsyncBaseHook.sol";
import { ICallbackHandler } from "contracts/interfaces/hooks/base/ICallbackHandler.sol";
import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { MockAsyncHook } from "test/foundry/mocks/MockAsyncHook.sol";
import { MockCallbackHandler } from "test/foundry/mocks/MockCallbackHandler.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";

// This contract tests the functionality of the AsyncBaseHook contract.
contract TestAsyncBaseHook is BaseTest {
    MockAsyncHook hook;
    MockCallbackHandler callbackHandler;

    event AsyncHookExecuted(
        address indexed hookAddress,
        address indexed callbackHandler,
        HookResult indexed result,
        bytes32 requestId,
        bytes contextData,
        bytes returnData
    );

    event AsyncHookCalledBack(
        address indexed hookAddress,
        address indexed callbackHandler,
        bytes32 requestId,
        bytes callbackData
    );

    function setUp() public override {
        super.setUp();

        vm.prank(admin);
        accessControl.grantRole(AccessControl.HOOK_CALLER_ROLE, address(this));

        hook = new MockAsyncHook(address(accessControl), address(this));
        callbackHandler = new MockCallbackHandler();
    }

    // This test verifies that the executeAsync function works correctly with valid parameters.
    function test_asyncBaseHook_executeAsyncValidParams() public {
        bytes memory hookParams = "0x1234";
        bytes memory hookConfig = "0x5678";
        bytes memory context = _getExecutionContext(hookConfig, hookParams);
        bytes memory expectedHookData = _getExpectedReturnData(hookConfig, hookParams);

        HookResult result;
        bytes memory hookData;
        bytes32 requestId;

        // Execute the async hook
        (result, hookData, requestId) = hook.executeAsync(
            context,
            address(callbackHandler)
        );

        // Check the result
        assertEq(uint(result), uint(HookResult.Pending));

        // Check the hook data
        assertEq0(hookData, expectedHookData);

        // Check the request ID
        assertEq32(requestId, hook.getRequestId(hookParams));
    }

     // This test verifies that the executeAsync function emits the correct event.
    function test_asyncBaseHook_executeAsyncVerifyEvent() public {
        bytes memory hookParams = "0x1234";
        bytes memory hookConfig = "0x5678";
        bytes32 expectedRequestId = hook.getRequestId(hookParams);
        bytes memory context = _getExecutionContext(hookConfig, hookParams);
        bytes memory expectedHookData = _getExpectedReturnData(hookConfig, hookParams);

        vm.expectEmit(address(hook));
        emit AsyncHookExecuted(
            address(hook),
            address(callbackHandler),
            HookResult.Pending,
            expectedRequestId,
            context,
            expectedHookData
        );
        // Execute the async hook
        hook.executeAsync(context, address(callbackHandler));
    }

    // This test verifies that the executeAsync function reverts when the callback handler is the zero address.
    function test_asyncBaseHook_revert_callbackHandlerIsZeroAddress() public {
        bytes memory hookParams = "0x1234";
        bytes memory hookConfig = "0x5678";
        bytes memory context = _getExecutionContext(hookConfig, hookParams);

        // Try to execute the async hook with a zero address callback handler
        vm.expectRevert(Errors.ZeroAddress.selector);
        hook.executeAsync(context, address(0));
    }

    // This test verifies that the executeAsync function reverts when the callback handler does not support the ICallbackHandler interface.
    function test_asyncBaseHook_revert_callbackHandlerIsNotICallbackHandler()
        public
    {
        bytes memory hookParams = "0x1234";
        bytes memory hookConfig = "0x5678";
        bytes memory context = _getExecutionContext(hookConfig, hookParams);

        // Try to execute the async hook with a callback handler that does not support the ICallbackHandler interface
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.UnsupportedInterface.selector,
                "ICallbackHandler"
            )
        );
        hook.executeAsync(context, address(this));
    }

    // This test verifies that the executeAsync function reverts when the caller does not have the HOOK_CALLER_ROLE.
    function test_asyncBaseHook_revert_NotQualifiedHookCaller() public {
        bytes memory hookParams = "0x1234";
        bytes memory hookConfig = "0x5678";
        bytes memory context = _getExecutionContext(hookConfig, hookParams);

        vm.startPrank(address(0x7777));
        // Try to handle the callback with an invalid request ID
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.MissingRole.selector,
                AccessControl.HOOK_CALLER_ROLE,
                address(0x7777)
            )
        );
        hook.executeAsync(context, address(this));
        vm.stopPrank();
    }

    function test_asyncBaseHook_handleCallbackValidParams() public {
        bytes memory hookParams = "0x1234";
        bytes memory hookConfig = "0x5678";
        bytes memory context = _getExecutionContext(hookConfig, hookParams);
        bytes32 expectedRequestId = hook.getRequestId(hookParams);
        bytes memory callbackData = abi.encode("PASS");
        bytes32 requestId;
        HookResult result;
        bytes memory hookData;

        // Execute the async hook
        (result, hookData, requestId) = hook.executeAsync(
            context,
            address(callbackHandler)
        );

        assertEq(requestId, expectedRequestId, "requestId is not equal");

        // verify that the requestId is mapped to callbackHandler
        assertEq(
            address(hook.callbackHandlers(requestId)),
            address(callbackHandler),
            "callbackHandler is not equal"
        );

        // simulate external service callback
        hook.handleCallback(requestId, callbackData);

        // verify request id is cleaned up after callback was handled for the requestId
        assertEq(address(hook.callbackHandlers(requestId)), address(0x0), "requestId is not cleaned up");
        assertEq(callbackHandler.lastHandledRequestId(), expectedRequestId, "last handled requestId is not equal");
        assertEq(callbackHandler.lastHandledCallbackData(), hook.getProcessedCallbackData(callbackData), "last handled callbackData is not equal");
    }

    function test_asyncBaseHook_handleCallbackVerifyEvent() public {
        bytes memory hookParams = "0x1234";
        bytes memory hookConfig = "0x5678";
        bytes memory context = _getExecutionContext(hookConfig, hookParams);
        bytes32 expectedRequestId = hook.getRequestId(hookParams);
        bytes memory callbackData = abi.encode("PASS");
        bytes32 requestId;
        HookResult result;
        bytes memory hookData;

        // Execute the async hook
        (result, hookData, requestId) = hook.executeAsync(
            context,
            address(callbackHandler)
        );

        assertEq(requestId, expectedRequestId);

        vm.expectEmit(address(hook));
        emit AsyncHookCalledBack(
            address(hook),
            address(callbackHandler),
            expectedRequestId,
            hook.getProcessedCallbackData(callbackData)
        );
        // simulate external service callback
        hook.handleCallback(requestId, callbackData);
    }

    function test_asyncBaseHook_revert_handleCallbackWithInvalidRequestId()
        public
    {
        bytes32 requestId = "0x9999";
        bytes memory callbackData = abi.encode("PASS");

        // Try to handle the callback with an invalid request ID
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Hook_InvalidAsyncRequestId.selector,
                requestId
            )
        );
        hook.handleCallback(requestId, callbackData);
    }

    function test_asyncBaseHook_revert_NotQualifiedCallbackCaller() public {
        bytes32 requestId = "0x9999";
        bytes memory callbackData = abi.encode("PASS");
        vm.startPrank(address(0x7777));
        // Try to handle the callback with an invalid request ID
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Hook_OnlyCallbackCallerCanCallback.selector,
                address(0x7777),
                address(this)
            )
        );
        hook.handleCallback(requestId, callbackData);
        vm.stopPrank();
    }

    function test_asyncBaseHook_revert_executeSyncCall() public {
        bytes memory hookParams = "0x1234";

        vm.expectRevert(Errors.Hook_UnsupportedSyncOperation.selector);
        hook.executeSync(hookParams);
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
