// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { TokenGatedHook } from "contracts/hooks/TokenGatedHook.sol";
import { HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { MockSyncHook } from "test/foundry/mocks/MockSyncHook.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import { MockERC721 } from "test/foundry/mocks/MockERC721.sol";
import { MockERC721Receiver } from "test/foundry/mocks/MockERC721Receiver.sol";
import { TokenGated } from "contracts/lib/hooks/TokenGated.sol";

contract TestTokenGatedHook is BaseTest {
    TokenGatedHook hook;
    MockERC721 tokenContract;
    MockERC721Receiver tokenOwner;

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

        hook = new TokenGatedHook(address(accessControl));
        tokenContract = new MockERC721();
        tokenOwner = new MockERC721Receiver(MockERC721Receiver.onERC721Received.selector, false);
        // Simulate user has ownership of the NFT
        tokenContract.mint(address(tokenOwner), 1);
    }

    function test_tokenGatedHook_hasOwnership() public {
        // create configuration of hook
        TokenGated.Config memory hookConfig = TokenGated.Config({
            tokenAddress: address(tokenContract)
        });
        bytes memory encodedConfig = abi.encode(hookConfig);
        // Hook validating the configuration
        hook.validateConfig(encodedConfig);

        // create parameters of executing the hook
        TokenGated.Params memory hookParams = TokenGated.Params({
            tokenOwner: address(tokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(encodedConfig, encodedParams);

        bytes memory expectedHookData = "";

        HookResult result;
        bytes memory hookData;

        // Execute the sync hook
        (result, hookData) = hook.executeSync(context);

        // Check the result
        assertEq(uint(result), uint(HookResult.Completed));

        // Check the hook data
        assertEq0(hookData, expectedHookData);
    }

    function test_tokenGatedHook_hasOwnershipVerifyEvent() public {
        // create configuration of hook
        TokenGated.Config memory hookConfig = TokenGated.Config({
            tokenAddress: address(tokenContract)
        });
        bytes memory encodedConfig = abi.encode(hookConfig);
        // Hook validating the configuration
        hook.validateConfig(encodedConfig);

        // create parameters of executing the hook
        TokenGated.Params memory hookParams = TokenGated.Params({
            tokenOwner: address(tokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(encodedConfig, encodedParams);

        bytes memory expectedHookData = "";

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

    function test_tokenGatedHook_revert_hasNoOwnership() public {
        MockERC721Receiver nonTokenOwner = new MockERC721Receiver(MockERC721Receiver.onERC721Received.selector, false);
        // create configuration of hook
        TokenGated.Config memory hookConfig = TokenGated.Config({
            tokenAddress: address(tokenContract)
        });
        bytes memory encodedConfig = abi.encode(hookConfig);
        // Hook validating the configuration
        hook.validateConfig(encodedConfig);

        // create parameters of executing the hook
        TokenGated.Params memory hookParams = TokenGated.Params({
            tokenOwner: address(nonTokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(encodedConfig, encodedParams);

        // Try to execute the hook without token ownership
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.TokenGatedHook_NotTokenOwner.selector,
                address(tokenContract),
                address(nonTokenOwner)
            )
        );
        hook.executeSync(context);
    }

    function test_tokenGatedHook_revert_ZeroTokenAddress() public {
        // create configuration of hook
        TokenGated.Config memory hookConfig = TokenGated.Config({
            // Invalid token address
            tokenAddress: address(0)
        });
        bytes memory encodedConfig = abi.encode(hookConfig);

        // create parameters of executing the hook
        TokenGated.Params memory hookParams = TokenGated.Params({
            tokenOwner: address(tokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(encodedConfig, encodedParams);

        // Try to execute the hook with invalid token contract address
        vm.expectRevert(Errors.ZeroAddress.selector);
        hook.executeSync(context);
    }

    function test_tokenGatedHook_revert_NonERC721Address() public {
        // create configuration of hook
        TokenGated.Config memory hookConfig = TokenGated.Config({
        // Invalid token address
            tokenAddress: address(0x77777)
        });
        bytes memory encodedConfig = abi.encode(hookConfig);

        // create parameters of executing the hook
        TokenGated.Params memory hookParams = TokenGated.Params({
            tokenOwner: address(tokenOwner)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(encodedConfig, encodedParams);

        // Try to execute the hook with invalid token contract address
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.UnsupportedInterface.selector,
                "IERC721"
            )
        );

        hook.executeSync(context);
    }

    function test_syncBaseHook_revert_InvalidOwnerAddress() public {
        // create configuration of hook
        TokenGated.Config memory hookConfig = TokenGated.Config({
        // Invalid token address
            tokenAddress: address(tokenContract)
        });
        bytes memory encodedConfig = abi.encode(hookConfig);

        // create parameters of executing the hook
        TokenGated.Params memory hookParams = TokenGated.Params({
            tokenOwner: address(0)
        });
        bytes memory encodedParams = abi.encode(hookParams);

        // Create Hook execution context which has hook's config and current parameters
        bytes memory context = _getExecutionContext(encodedConfig, encodedParams);

        // Try to execute the hook with invalid contract address
        vm.expectRevert(Errors.ZeroAddress.selector);

        hook.executeSync(context);
    }

    function test_tokenGatedHook_revert_InvalidConfig() public {
        // create configuration of hook
        TokenGated.Config memory hookConfig = TokenGated.Config({
        // Invalid token address
            tokenAddress: address(0)
        });
        bytes memory encodedConfig = abi.encode(hookConfig);

        vm.expectRevert(Errors.ZeroAddress.selector);
        hook.validateConfig(encodedConfig);
    }

    function _getExecutionContext(bytes memory hookConfig_, bytes memory hookParams_) internal pure returns (bytes memory) {
        Hook.ExecutionContext memory context = Hook.ExecutionContext({
            config: hookConfig_,
            params: hookParams_
        });
        return abi.encode(context);
    }

}
