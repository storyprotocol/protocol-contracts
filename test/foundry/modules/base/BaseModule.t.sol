// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";
import { MockBaseModule } from  "test/foundry/mocks/MockBaseModule.sol";
import { MockIPOrg } from "test/foundry/mocks/MockIPOrg.sol";
import { Errors } from  "contracts/lib/Errors.sol";
import { MockSyncHook } from "test/foundry/mocks/MockSyncHook.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";


contract BaseModuleTest is BaseTest {
    MockBaseModule module;
    IPAssetRegistry ipaRegistry = IPAssetRegistry(address(456));
    MockIPOrg mockIpOrg;
    MockBaseModule.ModuleExecutionParams moduleExecutionParams;

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);

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

    function test_baseModule_executeWithHooks() public {
        bytes memory configParams = abi.encode(uint256(123));
        vm.prank(address(moduleRegistry));
        module.configure(mockIpOrg, address(123), configParams);
        // register hooks
        address[] memory hooks = new address[](2);
        hooks[0] = address(new MockSyncHook(address(accessControl)));
        hooks[1] = address(new MockSyncHook(address(accessControl)));
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
        MockSyncHook failedHook = new MockSyncHook(address(accessControl));
        failedHook.setShouldExecuteSuccess(false);
        address[] memory hooks = new address[](2);
        hooks[0] = address(new MockSyncHook(address(accessControl)));
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

}
