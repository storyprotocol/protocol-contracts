// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { PolygonTokenHook } from "contracts/hooks/PolygonTokenHook.sol";
import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import { PolygonToken } from "contracts/lib/hooks/PolygonToken.sol";
import { MockERC721 } from "test/foundry/mocks/MockERC721.sol";
import { MockERC721Receiver } from "test/foundry/mocks/MockERC721Receiver.sol";
import { MockCallbackHandler } from "test/foundry/mocks/MockCallbackHandler.sol";
import { MockPolygonTokenClient } from "test/foundry/mocks/MockPolygonTokenClient.sol";

contract TestPolygonTokenHook is BaseTest {
    PolygonTokenHook hook;
    MockCallbackHandler callbackHandler;
    MockERC721 tokenContract;
    MockERC721Receiver tokenOwner;
    MockPolygonTokenClient polygonTokenClient;

    event PolygonTokenBalanceRequest(
        bytes32 indexed requestId,
        address indexed requester,
        address tokenAddress,
        address tokenOwnerAddress,
        address callbackAddr,
        bytes4 callbackFunctionSignature
    );

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

        callbackHandler = new MockCallbackHandler();
        polygonTokenClient = new MockPolygonTokenClient();

        hook = new PolygonTokenHook(
            address(accessControl),
            address(polygonTokenClient),
            address(this)
        );
        tokenContract = new MockERC721();
        tokenOwner = new MockERC721Receiver(
            MockERC721Receiver.onERC721Received.selector,
            false
        );
        // Simulate user has ownership of the NFT
        tokenContract.mint(address(tokenOwner), 1);
    }

    function test_PolygonTokenHook_requestAsyncCall_successfulSentEvent()
        public
    {
        // create configuration of hook
        PolygonToken.Config memory hookConfig = PolygonToken.Config({
            tokenAddress: address(tokenContract),
            balanceThreshold: 1
        });
        bytes memory encodedConfig = abi.encode(hookConfig);
        // Hook validating the configuration
        hook.validateConfig(encodedConfig);

        // create parameters of executing the hook
        PolygonToken.Params memory hookParams = PolygonToken.Params({
            tokenOwnerAddress: address(tokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(
            encodedConfig,
            encodedParams
        );

        bytes memory expectedHookData = "";

        HookResult result;
        bytes memory hookData;
        bytes32 requestId;
        bytes32 expectedRequestId = keccak256(
            abi.encodePacked(address(hook), uint256(0))
        );
        vm.expectEmit(address(polygonTokenClient));
        emit PolygonTokenBalanceRequest(
            expectedRequestId,
            address(this),
            address(tokenContract),
            address(tokenOwner),
            address(hook),
            hook.handleCallback.selector
        );
        // Execute the Async hook
        (result, hookData, requestId) = hook.executeAsync(
            context,
            address(callbackHandler)
        );
        assertEq(
            requestId,
            expectedRequestId,
            "requestId should be equal to expectedRequestId"
        );
        // Check the result
        assertEq(
            uint(result),
            uint(HookResult.Pending),
            "result should be equal to HookResult.Pending"
        );
        // Check the hook data
        assertEq0(
            hookData,
            expectedHookData,
            "hookData should be equal to expectedHookData"
        );
    }

    function test_PolygonTokenHook_handleCallback_successfulOwnershipVerification()
        public
    {
        // create configuration of hook
        PolygonToken.Config memory hookConfig = PolygonToken.Config({
            tokenAddress: address(tokenContract),
            balanceThreshold: 1
        });
        bytes memory encodedConfig = abi.encode(hookConfig);
        // Hook validating the configuration
        hook.validateConfig(encodedConfig);

        // create parameters of executing the hook
        PolygonToken.Params memory hookParams = PolygonToken.Params({
            tokenOwnerAddress: address(tokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(
            encodedConfig,
            encodedParams
        );

        bytes memory expectedHookData = "";

        HookResult result;
        bytes memory hookData;
        bytes32 requestId;
        bytes32 expectedRequestId = keccak256(
            abi.encodePacked(address(hook), uint256(0))
        );
        // Execute the Async hook
        (result, hookData, requestId) = hook.executeAsync(
            context,
            address(callbackHandler)
        );
        // Check the result
        assertEq(
            uint(result),
            uint(HookResult.Pending),
            "result should be equal to HookResult.Pending"
        );
        // Check the hook data
        assertEq0(
            hookData,
            expectedHookData,
            "hookData should be equal to expectedHookData"
        );
        // simulate callback from oracle client and tokenOwner has enough balance
        hook.handleCallback(requestId, 1);
        // verify request id is cleaned up after callback was handled for the requestId
        assertEq(
            address(hook.callbackHandlers(requestId)),
            address(0x0),
            "requestId is not cleaned up"
        );
        assertEq(
            callbackHandler.lastHandledRequestId(),
            expectedRequestId,
            "last handled requestId is not equal"
        );
        assertEq(
            callbackHandler.lastHandledCallbackData(),
            abi.encode(true, ""),
            "last handled callbackData is not equal"
        );
    }

    function test_PolygonTokenHook_handleCallback_NotEnoughBalance() public {
        // create configuration of hook
        PolygonToken.Config memory hookConfig = PolygonToken.Config({
            tokenAddress: address(tokenContract),
            balanceThreshold: 1
        });
        bytes memory encodedConfig = abi.encode(hookConfig);
        // Hook validating the configuration
        hook.validateConfig(encodedConfig);

        // create parameters of executing the hook
        PolygonToken.Params memory hookParams = PolygonToken.Params({
            tokenOwnerAddress: address(tokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(
            encodedConfig,
            encodedParams
        );

        bytes memory expectedHookData = "";

        HookResult result;
        bytes memory hookData;
        bytes32 requestId;
        bytes32 expectedRequestId = keccak256(
            abi.encodePacked(address(hook), uint256(0))
        );
        // Execute the Async hook
        (result, hookData, requestId) = hook.executeAsync(
            context,
            address(callbackHandler)
        );
        // Check the result
        assertEq(
            uint(result),
            uint(HookResult.Pending),
            "result should be equal to HookResult.Pending"
        );
        // Check the hook data
        assertEq0(
            hookData,
            expectedHookData,
            "hookData should be equal to expectedHookData"
        );
        // simulate callback from oracle client and tokenOwner has NOT enough balance
        hook.handleCallback(requestId, 0);
        // verify request id is cleaned up after callback was handled for the requestId
        assertEq(
            address(hook.callbackHandlers(requestId)),
            address(0x0),
            "requestId is not cleaned up"
        );
        assertEq(
            callbackHandler.lastHandledRequestId(),
            expectedRequestId,
            "last handled requestId is not equal"
        );
        assertEq(
            callbackHandler.lastHandledCallbackData(),
            abi.encode(false, "Balance of Token is not enough"),
            "last handled callbackData is not equal"
        );
    }

    function test_PolygonTokenHook_revert_zeroAddress() public {
        // create configuration of hook
        PolygonToken.Config memory hookConfig = PolygonToken.Config({
            // Should revert for zero address
            tokenAddress: address(0),
            balanceThreshold: 1
        });
        bytes memory encodedConfig = abi.encode(hookConfig);

        // create parameters of executing the hook
        PolygonToken.Params memory hookParams = PolygonToken.Params({
            tokenOwnerAddress: address(tokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(
            encodedConfig,
            encodedParams
        );

        bytes memory expectedHookData = "";
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Hook_InvalidHookConfig.selector,
                "tokenAddress is 0"
            )
        );
        hook.executeAsync(context, address(callbackHandler));
    }

    function test_PolygonTokenHook_revert_zeroBalanceThreshold() public {
        // create configuration of hook
        PolygonToken.Config memory hookConfig = PolygonToken.Config({
            tokenAddress: address(tokenContract),
            // Should revert for zero threshold
            balanceThreshold: 0
        });
        bytes memory encodedConfig = abi.encode(hookConfig);

        // create parameters of executing the hook
        PolygonToken.Params memory hookParams = PolygonToken.Params({
            tokenOwnerAddress: address(tokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(
            encodedConfig,
            encodedParams
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.Hook_InvalidHookConfig.selector,
                "balanceThreshold is 0"
            )
        );
        hook.executeAsync(context, address(callbackHandler));
    }

    function _getExecutionContext(
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal pure returns (bytes memory) {
        Hook.ExecutionContext memory context = Hook.ExecutionContext({
            config: hookConfig_,
            params: hookParams_
        });
        return abi.encode(context);
    }
}
