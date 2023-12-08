// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { ModuleKey } from "contracts/lib/modules/Module.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";
import { MockBaseModule } from  "test/foundry/mocks/MockBaseModule.sol";
import { MockIPOrg } from "test/foundry/mocks/MockIPOrg.sol";
import { Errors } from  "contracts/lib/Errors.sol";
import { MockSyncHook } from "test/foundry/mocks/MockSyncHook.sol";
import { MockAsyncHook } from "test/foundry/mocks/MockAsyncHook.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";


contract BaseModuleTest is BaseTest {

    ModuleKey constant TEST_MODULE = ModuleKey.wrap(keccak256(abi.encodePacked("test")));

    MockBaseModule module;
    IPAssetRegistry ipaRegistry = IPAssetRegistry(address(456));
    MockIPOrg mockIpOrg;
    MockBaseModule.ModuleExecutionParams moduleExecutionParams;

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);
    event RequestFailed(address indexed sender, string reason);

    function setUp() public override {
        super.setUp();

        mockIpOrg = new MockIPOrg(admin);
        vm.startPrank(admin);
        module = new MockBaseModule(admin, BaseModule.ModuleConstruction(ipaRegistry, moduleRegistry, licenseRegistry, ipOrgController));
        accessControl.grantRole(AccessControl.HOOK_CALLER_ROLE, address(module));
        vm.stopPrank();
        moduleExecutionParams = MockBaseModule.ModuleExecutionParams({
            paramA: 123,
            paramC: 456,
            someHookRegisteringRelatedInfo: "HookRegistryRelatedInfo"
        });
    }

    function test_baseModule_revert_unauthorizedCaller() public {
        moduleRegistry.registerProtocolModule(TEST_MODULE, module);
        vm.expectRevert(Errors.BaseModule_Unauthorized.selector);
        module.test();
    }

    function test_baseModule_revert_constructorIpaRegistryIsZero() public {
        vm.prank(admin);
        vm.expectRevert(Errors.BaseModule_ZeroIpaRegistry.selector);
        new MockBaseModule(
            admin,
            BaseModule.ModuleConstruction(
                IPAssetRegistry(address(0)),
                moduleRegistry,
                licenseRegistry,
                ipOrgController
            )
        );
    }

    function test_baseModule_revert_constructorModuleRegistryIsZero() public {
        vm.prank(admin);
        vm.expectRevert(Errors.HookRegistry_ZeroModuleRegistry.selector);
        module = new MockBaseModule(
            admin,
            BaseModule.ModuleConstruction(
                ipaRegistry,
                ModuleRegistry(address(0)),
                licenseRegistry,
                ipOrgController
            )
        );
    }

    function test_baseModule_setup() public {
        assertEq(address(module.IPA_REGISTRY()), address(ipaRegistry));
        assertEq(address(module.MODULE_REGISTRY()), address(moduleRegistry));
    }

    function test_baseModule_passesConfigParams() public {
        bytes memory params = abi.encode(uint256(123));
        vm.prank(address(moduleRegistry));
        module.configure(mockIpOrg, address(123), params);
        assertEq(module.callStackAt(0).caller, address(123));
        assertEq(module.callStackAt(0).params, params);
    }

    function test_baseModule_revert_configureNotModuleRegistry() public {
        bytes memory params = abi.encode(uint256(123));
        vm.expectRevert(Errors.BaseModule_OnlyModuleRegistry.selector);
        module.configure(mockIpOrg, address(123), params);
    }

    function test_baseModule_correctExecutionOrderAndParams() public {
        vm.startPrank(address(moduleRegistry));
        bytes memory params = abi.encode(moduleExecutionParams);
        vm.expectEmit(true, true, true, true);
        emit RequestCompleted(address(123));
        module.execute(mockIpOrg, address(123), params, new bytes[](0), new bytes[](0));
        vm.stopPrank();
        assertEq(module.callStackAt(0).caller, address(123));
        assertEq(module.callStackAt(0).params, params);
        assertEq(module.callStackAt(0).ipOrg, address(mockIpOrg));
        assertEq(module.callStackAt(1).caller, address(123));
        assertEq(module.callStackAt(1).params, params);
        assertEq(module.callStackAt(1).ipOrg, address(mockIpOrg));
    }

    function test_baseModule_revert_executeNotModuleRegistry() public {
        bytes memory params = abi.encode(uint256(123));
        vm.expectRevert(Errors.BaseModule_OnlyModuleRegistry.selector);
        module.execute(mockIpOrg, address(123), params, new bytes[](0), new bytes[](0));
    }

    function test_baseModule_revertPreHookWrongParamsLength() public {
        vm.startPrank(address(moduleRegistry));
        bytes memory params = abi.encode(moduleExecutionParams);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.BaseModule_HooksParamsLengthMismatch.selector,
                uint8(HookRegistry.HookType.PreAction)
            )
        );
        module.execute(mockIpOrg, address(123), params, new bytes[](1), new bytes[](0));
        vm.stopPrank();
    }

    function test_baseModule_revertPostHookWrongParamsLength() public {
        vm.startPrank(address(moduleRegistry));
        bytes memory params = abi.encode(moduleExecutionParams);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.BaseModule_HooksParamsLengthMismatch.selector,
                uint8(HookRegistry.HookType.PostAction)
            )
        );
        module.execute(mockIpOrg, address(123), params, new bytes[](0), new bytes[](1));
        vm.stopPrank();
    }
    function test_baseModule_executeWithAsyncHooks() public {
        bytes memory configParams = abi.encode(uint256(123));
        vm.prank(address(moduleRegistry));
        module.configure(mockIpOrg, address(123), configParams);

        (MockAsyncHook asyncHook, bytes32 requestId) = _executeModuleWithAsyncHook();
        // simulate external service callback
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit RequestCompleted(address(123));
        asyncHook.handleCallback(requestId, abi.encode("PASS"));
        vm.stopPrank();
    }

    function test_baseModule_executeWithAsyncHooksFail() public {
        bytes memory configParams = abi.encode(uint256(123));
        vm.prank(address(moduleRegistry));
        module.configure(mockIpOrg, address(123), configParams);

        (MockAsyncHook asyncHook, bytes32 requestId) = _executeModuleWithAsyncHook();
        // simulate external service callback
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit RequestFailed(address(123), "EXPECTED_FAILURE");
        asyncHook.handleCallback(requestId, abi.encode("EXPECTED_FAILURE"));
        vm.stopPrank();
    }

    function test_baseModule_executeWithHooks() public {
        bytes memory configParams = abi.encode(uint256(123));
        vm.prank(address(moduleRegistry));
        module.configure(mockIpOrg, address(123), configParams);
        // register hooks
        address[] memory hooks = new address[](2);
        hooks[0] = address(_deploySyncHook(1));
        hooks[1] = address(_deploySyncHook(2));
        bytes[] memory hooksConfig = new bytes[](2);
        hooksConfig[0] = abi.encode("Hook1Config");
        hooksConfig[1] = abi.encode("Hook2Config");
        // used to generate registryKey. could be relation type, etc.
        string memory hookRegistryRelatedInfo = "HookRegistryRelatedInfo";
        vm.startPrank(admin);

        module.registerHooks(
            HookRegistry.HookType.PreAction,
            mockIpOrg,
            hookRegistryRelatedInfo,
            hooks,
            hooksConfig
        );

        module.registerHooks(
            HookRegistry.HookType.PostAction,
            mockIpOrg,
            hookRegistryRelatedInfo,
            hooks,
            hooksConfig
        );
        vm.stopPrank();
        // execute module
        vm.startPrank(address(moduleRegistry));
        MockBaseModule.ModuleExecutionParams memory executionParamsStruct = MockBaseModule.ModuleExecutionParams({
            paramA: 123,
            paramC: 456,
            someHookRegisteringRelatedInfo: hookRegistryRelatedInfo
        });
        bytes memory executionParams = abi.encode(executionParamsStruct);
        bytes[] memory hooksParams = new bytes[](2);
        hooksParams[0] = abi.encode("Hook1Params");
        hooksParams[1] = abi.encode("Hook2Params");
        vm.expectEmit(true, true, true, true);
        emit RequestCompleted(address(123));
        module.execute(mockIpOrg, address(123), executionParams, hooksParams, hooksParams);
        vm.stopPrank();
    }

    function test_baseModule_revert_hooksFailed() public {
        bytes memory configParams = abi.encode(uint256(123));
        vm.prank(address(moduleRegistry));
        module.configure(mockIpOrg, address(123), configParams);
        // register hooks
        MockSyncHook failedHook = _deploySyncHook(1);
        failedHook.setShouldExecuteSuccess(false);
        address[] memory hooks = new address[](2);
        hooks[0] = address(_deploySyncHook(2));
        hooks[1] = address(failedHook);
        bytes[] memory hooksConfig = new bytes[](2);
        hooksConfig[0] = abi.encode("Hook1Config");
        hooksConfig[1] = abi.encode("Hook2Config");
        // used to generate registryKey. could be relation type, etc.
        string memory hookRegistryRelatedInfo = "HookRegistryRelatedInfo";
        vm.startPrank(admin);

        module.registerHooks(
            HookRegistry.HookType.PreAction,
            mockIpOrg,
            hookRegistryRelatedInfo,
            hooks,
            hooksConfig
        );

        module.registerHooks(
            HookRegistry.HookType.PostAction,
            mockIpOrg,
            hookRegistryRelatedInfo,
            hooks,
            hooksConfig
        );
        vm.stopPrank();
        // execute module
        vm.startPrank(address(moduleRegistry));
        MockBaseModule.ModuleExecutionParams memory executionParamsStruct = MockBaseModule.ModuleExecutionParams({
            paramA: 123,
            paramC: 456,
            someHookRegisteringRelatedInfo: hookRegistryRelatedInfo
        });
        bytes memory executionParams = abi.encode(executionParamsStruct);
        bytes[] memory hooksParams = new bytes[](2);
        hooksParams[0] = abi.encode("Hook1Params");
        hooksParams[1] = abi.encode("Hook2Params");
        vm.expectRevert("EXPECTED_FAILURE");
        module.execute(mockIpOrg, address(123), executionParams, hooksParams, hooksParams);
        vm.stopPrank();
    }

    function _deploySyncHook(uint256 seed_) internal returns (MockSyncHook result) {
        bytes memory code = abi.encodePacked(
            type(MockSyncHook).creationCode, abi.encode(address(accessControl)));
        result = MockSyncHook(_deployHook(code, Hook.SYNC_FLAG, seed_));
        moduleRegistry.registerProtocolHook(string(abi.encodePacked("SyncHook-", seed_)), result);
    }

    function _deployAsyncHook(uint256 seed_) internal returns (MockAsyncHook result) {
        bytes memory code = abi.encodePacked(
            type(MockAsyncHook).creationCode, abi.encode(address(accessControl), admin));
        result = MockAsyncHook(_deployHook(code, Hook.ASYNC_FLAG, seed_));
        moduleRegistry.registerProtocolHook(string(abi.encodePacked("AsyncHook-", seed_)), result);
    }

    function _executeModuleWithAsyncHook() internal returns (MockAsyncHook asyncHook, bytes32 requestId) {
        // register both async and sync hooks
        address[] memory preHooks = new address[](2);
        preHooks[0] = address(_deployAsyncHook(1));
        preHooks[1] = address(_deploySyncHook(2));
        bytes[] memory preHooksConfig = new bytes[](2);
        preHooksConfig[0] = abi.encode("AsyncHookConfig");
        preHooksConfig[1] = abi.encode("SyncHookConfig");

        address[] memory postHooks = new address[](2);
        postHooks[0] = address(_deploySyncHook(3));
        postHooks[1] = address(_deploySyncHook(4));
        bytes[] memory postHooksConfig = new bytes[](2);
        postHooksConfig[0] = abi.encode("SyncHookConfig");
        postHooksConfig[1] = abi.encode("SyncHookConfig");
        // used to generate registryKey. could be relation type, etc.
        string memory hookRegistryRelatedInfo = "HookRegistryRelatedInfo";
        vm.startPrank(admin);
        module.registerHooks(
            HookRegistry.HookType.PreAction,
            mockIpOrg,
            hookRegistryRelatedInfo,
            preHooks,
            preHooksConfig
        );
        module.registerHooks(
            HookRegistry.HookType.PostAction,
            mockIpOrg,
            hookRegistryRelatedInfo,
            postHooks,
            postHooksConfig
        );
        vm.stopPrank();
        // execute module
        vm.startPrank(address(moduleRegistry));
        MockBaseModule.ModuleExecutionParams memory executionParamsStruct = MockBaseModule.ModuleExecutionParams({
            paramA: 123,
            paramC: 456,
            someHookRegisteringRelatedInfo: hookRegistryRelatedInfo
        });
        bytes memory executionParams = abi.encode(executionParamsStruct);
        bytes[] memory preHooksParams = new bytes[](2);
        preHooksParams[0] = abi.encode("AsyncHookParams");
        preHooksParams[1] = abi.encode("SyncHookParams");
        bytes[] memory postHooksParams = new bytes[](2);
        postHooksParams[0] = abi.encode("AsyncHookParams");
        postHooksParams[1] = abi.encode("SyncHookParams");
        vm.expectEmit(true, true, true, true);
        emit RequestPending(address(123));
        module.execute(mockIpOrg, address(123), executionParams, preHooksParams, postHooksParams);
        vm.stopPrank();
        asyncHook = MockAsyncHook(preHooks[0]);
        requestId = asyncHook.getRequestId(preHooksParams[0]);
    }
}
