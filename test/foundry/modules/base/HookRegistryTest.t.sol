// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";
import { MockHookRegistry } from "test/foundry/mocks/MockHookRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { MockBaseHook } from "test/foundry/mocks/MockBaseHook.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { MockIPOrg } from "test/foundry/mocks/MockIPOrg.sol";

contract HookRegistryTest is BaseTest {
    MockHookRegistry hookRegistry;

    event HooksRegistered(HookRegistry.HookType indexed hType, bytes32 indexed registryKey, address[] hooks);
    event HooksCleared(HookRegistry.HookType indexed hType, bytes32 indexed registryKey);

    function setUp() public override {
        super.setUp();

        vm.prank(admin);
        hookRegistry = new MockHookRegistry(moduleRegistry);
    }

    function test_hookRegistry_registerPreHooks() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PreAction, registryKey, hooks);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.stopPrank();
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKey, 0), hooks[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKey, 1), hooks[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKey, 0), hooksConfig[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKey, 1), hooksConfig[1]);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PreAction, registryKey), hooks.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKey), hooksConfig.length);
    }

    function test_hookRegistry_registerPreHooksClearsHooksIfNotEmpty() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.expectEmit(true, false, false, true);
        emit HooksCleared(HookRegistry.HookType.PreAction, registryKey);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.stopPrank();
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKey, 0), hooks[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKey, 1), hooks[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKey, 0), hooksConfig[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKey, 1), hooksConfig[1]);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PreAction, registryKey), hooks.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKey), hooksConfig.length);
    }

    function test_hookRegistry_registerPostHooks() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PostAction, registryKey, hooks);
        hookRegistry.registerHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.stopPrank();
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PostAction, registryKey, 0), hooks[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PostAction, registryKey, 1), hooks[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PostAction, registryKey, 0), hooksConfig[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PostAction, registryKey, 1), hooksConfig[1]);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PostAction, registryKey), hooks.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PostAction, registryKey), hooksConfig.length);
    }

    function test_hookRegistry_registerPostHooksClearsHooksIfNotEmpty() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);
        hookRegistry.registerHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.expectEmit(true, false, false, true);
        emit HooksCleared(HookRegistry.HookType.PostAction, registryKey);
        hookRegistry.registerHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.stopPrank();
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PostAction, registryKey, 0), hooks[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PostAction, registryKey, 1), hooks[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PostAction, registryKey, 0), hooksConfig[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PostAction, registryKey, 1), hooksConfig[1]);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PostAction, registryKey), hooks.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PostAction, registryKey), hooksConfig.length);
    }

    function test_hookRegistry_revertRegisterHooksCallerNotIpOrgOwner() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.expectRevert(Errors.HookRegistry_CallerNotIPOrgOwner.selector);
        hookRegistry.registerHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey, hooks, hooksConfig);
    }

    function test_hookRegistry_revertRegisterMaxHooksExceeded() public {
        address[] memory hooks = new address[](hookRegistry.MAX_HOOKS() + 1);
        bytes[] memory hooksConfig = new bytes[](hookRegistry.MAX_HOOKS() + 1);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);
        for(uint256 i = 0; i <= hookRegistry.MAX_HOOKS(); i++) {
            hooks[i] = address(new MockBaseHook(address(accessControl)));
            hooksConfig[i] = abi.encode("HookConfig", i + 1);
        }
        vm.expectRevert(Errors.HookRegistry_MaxHooksExceeded.selector);
        hookRegistry.registerHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.expectRevert(Errors.HookRegistry_MaxHooksExceeded.selector);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.stopPrank();
    }

    function test_hookRegistry_revertRegisterDuplicatedHook() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        hooks[1] = hooks[0];
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);
        vm.expectRevert(Errors.HookRegistry_RegisteringDuplicatedHook.selector);
        hookRegistry.registerHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.stopPrank();
    }

    function test_hookRegistry_getters() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);

        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg, registryKey, hooks, hooksConfig);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKey, 0), hooks[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKey, 1), hooks[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKey, 0), hooksConfig[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKey, 1), hooksConfig[1]);
        assertEq(hookRegistry.hookIndex(HookRegistry.HookType.PreAction, registryKey, hooks[0]), 0);
        assertEq(hookRegistry.hookIndex(HookRegistry.HookType.PreAction, registryKey, hooks[1]), 1);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PreAction, registryKey), hooks.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKey), hooksConfig.length);
        assertEq(hookRegistry.isRegistered(HookRegistry.HookType.PreAction, registryKey, hooks[0]), true);
        assertEq(hookRegistry.isRegistered(HookRegistry.HookType.PreAction, registryKey, hooks[1]), true);

        hookRegistry.registerHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey, hooks, hooksConfig);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PostAction, registryKey, 0), hooks[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PostAction, registryKey, 1), hooks[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PostAction, registryKey, 0), hooksConfig[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PostAction, registryKey, 1), hooksConfig[1]);
        assertEq(hookRegistry.hookIndex(HookRegistry.HookType.PostAction, registryKey, hooks[0]), 0);
        assertEq(hookRegistry.hookIndex(HookRegistry.HookType.PostAction, registryKey, hooks[1]), 1);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PostAction, registryKey), hooks.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PostAction, registryKey), hooksConfig.length);
        assertEq(hookRegistry.isRegistered(HookRegistry.HookType.PostAction, registryKey, hooks[0]), true);
        assertEq(hookRegistry.isRegistered(HookRegistry.HookType.PostAction, registryKey, hooks[1]), true);

        vm.stopPrank();
    }

    function test_hookRegistry_clearPreHooks() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.expectEmit(true, true, false, true);
        emit HooksCleared(HookRegistry.HookType.PreAction,  registryKey);
        hookRegistry.clearHooks(HookRegistry.HookType.PreAction, ipOrg, registryKey);
        vm.stopPrank();
        assertEq(hookRegistry.hookIndex(HookRegistry.HookType.PreAction, registryKey, hooks[0]), hookRegistry.INDEX_NOT_FOUND());
        assertEq(hookRegistry.hookIndex(HookRegistry.HookType.PreAction, registryKey, hooks[1]), hookRegistry.INDEX_NOT_FOUND());
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKey), 0);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PreAction, registryKey), 0);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKey), 0);
    }

    function test_hookRegistry_clearPostHooks() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);
        hookRegistry.registerHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.expectEmit(true, true, false, true);
        emit HooksCleared(HookRegistry.HookType.PostAction, registryKey);
        hookRegistry.clearHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey);
        vm.stopPrank();
        assertEq(hookRegistry.hookIndex(HookRegistry.HookType.PostAction, registryKey, hooks[0]), hookRegistry.INDEX_NOT_FOUND());
        assertEq(hookRegistry.hookIndex(HookRegistry.HookType.PostAction, registryKey, hooks[1]), hookRegistry.INDEX_NOT_FOUND());
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PostAction, registryKey), 0);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PostAction, registryKey), 0);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PostAction, registryKey), 0);
    }

    function test_hookRegistry_revertClearHooksCallerNotAdmin() public {
        (address[] memory hooks, bytes[] memory hooksConfig) = _generateHooks(2);
        address ipOrgOwner = address(0x789);
        IIPOrg ipOrg = new MockIPOrg(ipOrgOwner);
        bytes32 registryKey = hookRegistry.hookRegistryKey(address(ipOrg), "RelationshipType_A");
        vm.startPrank(ipOrgOwner);
        hookRegistry.registerHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey, hooks, hooksConfig);
        vm.stopPrank();
        vm.expectRevert(Errors.HookRegistry_CallerNotIPOrgOwner.selector);
        hookRegistry.clearHooks(HookRegistry.HookType.PostAction, ipOrg, registryKey);
    }

    function test_hookRegistry_registerHooksWithMultipleRegistryKeys() public {
        address hook1 = address(new MockBaseHook(address(accessControl)));
        address hook2 = address(new MockBaseHook(address(accessControl)));
        address hook3 = address(new MockBaseHook(address(accessControl)));
        address hook5 = address(new MockBaseHook(address(accessControl)));
        moduleRegistry.registerProtocolHook("Hook-1", IHook(hook1));
        moduleRegistry.registerProtocolHook("Hook-2", IHook(hook2));
        moduleRegistry.registerProtocolHook("Hook-3", IHook(hook3));
        moduleRegistry.registerProtocolHook("Hook-5", IHook(hook5));

        address[] memory hooksA = new address[](2);
        hooksA[0] = hook1;
        hooksA[1] = hook2;
        bytes[] memory hooksConfigA = new bytes[](2);
        hooksConfigA[0] = abi.encode("Hook1Config");
        hooksConfigA[1] = abi.encode("Hook2Config");
        IIPOrg ipOrg1 = new MockIPOrg(address(0x789));
        bytes32 registryKeyA = hookRegistry.hookRegistryKey(address(ipOrg1), "RelationshipType_A");

        // hooks B shares same ipOrg with hooks A
        address[] memory hooksB = new address[](2);
        hooksB[0] = hook3;
        hooksB[1] = hook5;
        bytes[] memory hooksConfigB = new bytes[](2);
        hooksConfigB[0] = abi.encode("Hook3Config");
        hooksConfigB[1] = abi.encode("Hook5Config");
        bytes32 registryKeyB = hookRegistry.hookRegistryKey(address(ipOrg1), "RelationshipType_B");

        address[] memory hooksC = new address[](2);
        hooksC[0] = hook2;
        hooksC[1] = hook3;
        bytes[] memory hooksConfigC = new bytes[](2);
        hooksConfigC[0] = abi.encode("Hook2Config");
        hooksConfigC[1] = abi.encode("Hook3Config");
        IIPOrg ipOrg2 = new MockIPOrg(address(0x999));
        bytes32 registryKeyC = hookRegistry.hookRegistryKey(address(ipOrg2), "RelationshipType_C");
        vm.startPrank(address(0x789));
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PreAction, registryKeyA, hooksA);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyA, hooksA, hooksConfigA);
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PreAction, registryKeyB, hooksB);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyB, hooksB, hooksConfigB);
        vm.stopPrank();
        vm.startPrank(address(0x999));
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PreAction, registryKeyC, hooksC);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg2, registryKeyC, hooksC, hooksConfigC);
        vm.stopPrank();
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyA, 0), hooksA[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyA, 1), hooksA[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyA, 0), hooksConfigA[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyA, 1), hooksConfigA[1]);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PreAction, registryKeyA), hooksA.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKeyA), hooksConfigA.length);

        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyB, 0), hooksB[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyB, 1), hooksB[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyB, 0), hooksConfigB[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyB, 1), hooksConfigB[1]);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PreAction, registryKeyB), hooksB.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKeyB), hooksConfigB.length);

        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyC, 0), hooksC[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyC, 1), hooksC[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyC, 0), hooksConfigC[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyC, 1), hooksConfigC[1]);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PreAction, registryKeyC), hooksC.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKeyC), hooksConfigC.length);
    }

    function test_hookRegistry_onlyClearHooksForSpecificRegistryKey() public {
        address hook1 = address(new MockBaseHook(address(accessControl)));
        address hook2 = address(new MockBaseHook(address(accessControl)));
        address hook3 = address(new MockBaseHook(address(accessControl)));
        address hook5 = address(new MockBaseHook(address(accessControl)));
        address hook6 = address(new MockBaseHook(address(accessControl)));
        address hook7 = address(new MockBaseHook(address(accessControl)));
        address hook8 = address(new MockBaseHook(address(accessControl)));

        moduleRegistry.registerProtocolHook("Hook-1", IHook(hook1));
        moduleRegistry.registerProtocolHook("Hook-2", IHook(hook2));
        moduleRegistry.registerProtocolHook("Hook-3", IHook(hook3));
        moduleRegistry.registerProtocolHook("Hook-5", IHook(hook5));
        moduleRegistry.registerProtocolHook("Hook-6", IHook(hook6));
        moduleRegistry.registerProtocolHook("Hook-7", IHook(hook7));
        moduleRegistry.registerProtocolHook("Hook-8", IHook(hook8));

        address[] memory hooksA = new address[](2);
        hooksA[0] = hook1;
        hooksA[1] = hook2;
        bytes[] memory hooksConfigA = new bytes[](2);
        hooksConfigA[0] = abi.encode("Hook1Config");
        hooksConfigA[1] = abi.encode("Hook2Config");
        address ipOrgOwner1 = address(0x789);
        IIPOrg ipOrg1 = new MockIPOrg(ipOrgOwner1);
        bytes32 registryKeyA = hookRegistry.hookRegistryKey(address(ipOrg1), "RelationshipType_A");

        // hooks B shares same ipOrg with hooks A
        address[] memory hooksB = new address[](2);
        hooksB[0] = hook3;
        hooksB[1] = hook5;
        bytes[] memory hooksConfigB = new bytes[](2);
        hooksConfigB[0] = abi.encode("Hook3Config");
        hooksConfigB[1] = abi.encode("Hook5Config");
        bytes32 registryKeyB = hookRegistry.hookRegistryKey(address(ipOrg1), "RelationshipType_B");

        address[] memory hooksC = new address[](3);
        hooksC[0] = hook6;
        hooksC[1] = hook7;
        hooksC[2] = hook8;
        bytes[] memory hooksConfigC = new bytes[](3);
        hooksConfigC[0] = abi.encode("Hook6Config");
        hooksConfigC[1] = abi.encode("Hook7Config");
        hooksConfigC[2] = abi.encode("Hook8Config");

        vm.startPrank(ipOrgOwner1);
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PreAction, registryKeyA, hooksA);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyA, hooksA, hooksConfigA);
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PreAction, registryKeyB, hooksB);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyB, hooksB, hooksConfigB);

        // Expecting both clear and register events should be emitted
        vm.expectEmit(true, false, false, true);
        emit HooksCleared(HookRegistry.HookType.PreAction, registryKeyA);
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PreAction, registryKeyA, hooksC);
        // register new hooks with the same registryKeyA, expecting the existing hooks should be replaced
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyA, hooksC, hooksConfigC);

        vm.stopPrank();

        // registryKeyA should map to hooks C now
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyA, 0), hooksC[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyA, 1), hooksC[1]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyA, 2), hooksC[2]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyA, 0), hooksConfigC[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyA, 1), hooksConfigC[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyA, 2), hooksConfigC[2]);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PreAction, registryKeyA), hooksC.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKeyA), hooksConfigC.length);

        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyB, 0), hooksB[0]);
        assertEq(hookRegistry.hookAt(HookRegistry.HookType.PreAction, registryKeyB, 1), hooksB[1]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyB, 0), hooksConfigB[0]);
        assertEq(hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, registryKeyB, 1), hooksConfigB[1]);
        assertEq(hookRegistry.totalHooks(HookRegistry.HookType.PreAction, registryKeyB), hooksB.length);
        assertEq(hookRegistry.totalHooksConfig(HookRegistry.HookType.PreAction, registryKeyB), hooksConfigB.length);
    }


    function test_hookRegistry_revertHookAtNonExistRegistryKey() public {
        address hook1 = address(new MockBaseHook(address(accessControl)));
        address hook2 = address(new MockBaseHook(address(accessControl)));
        moduleRegistry.registerProtocolHook("Hook-1", IHook(hook1));
        moduleRegistry.registerProtocolHook("Hook-2", IHook(hook2));

        address[] memory hooksA = new address[](2);
        hooksA[0] = hook1;
        hooksA[1] = hook2;
        bytes[] memory hooksConfigA = new bytes[](2);
        hooksConfigA[0] = abi.encode("Hook1Config");
        hooksConfigA[1] = abi.encode("Hook2Config");
        address ipOrgOwner1 = address(0x789);
        IIPOrg ipOrg1 = new MockIPOrg(ipOrgOwner1);
        bytes32 registryKeyA = hookRegistry.hookRegistryKey(address(ipOrg1), "RelationshipType_A");
        vm.startPrank(ipOrgOwner1);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyA, hooksA, hooksConfigA);
        vm.stopPrank();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.HookRegistry_IndexOutOfBounds.selector,
                0
            )
        );
        hookRegistry.hookAt(HookRegistry.HookType.PreAction, keccak256(abi.encode("NonExistRegistryKey")), 0);
    }

    function test_hookRegistry_revertHookConfigAtNonExistRegistryKey() public {
        address hook1 = address(new MockBaseHook(address(accessControl)));
        address hook2 = address(new MockBaseHook(address(accessControl)));
        moduleRegistry.registerProtocolHook("Hook-1", IHook(hook1));
        moduleRegistry.registerProtocolHook("Hook-2", IHook(hook2));

        address[] memory hooksA = new address[](2);
        hooksA[0] = hook1;
        hooksA[1] = hook2;
        bytes[] memory hooksConfigA = new bytes[](2);
        hooksConfigA[0] = abi.encode("Hook1Config");
        hooksConfigA[1] = abi.encode("Hook2Config");
        address ipOrgOwner1 = address(0x789);
        IIPOrg ipOrg1 = new MockIPOrg(ipOrgOwner1);
        bytes32 registryKeyA = hookRegistry.hookRegistryKey(address(ipOrg1), "RelationshipType_A");
        vm.startPrank(ipOrgOwner1);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyA, hooksA, hooksConfigA);
        vm.stopPrank();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.HookRegistry_IndexOutOfBounds.selector,
                0
            )
        );
        hookRegistry.hookConfigAt(HookRegistry.HookType.PreAction, keccak256(abi.encode("NonExistRegistryKey")), 0);
    }

    function test_hookRegistry_revertHooksConfigMismatch() public {
        address hook1 = address(new MockBaseHook(address(accessControl)));
        address hook2 = address(new MockBaseHook(address(accessControl)));
        moduleRegistry.registerProtocolHook("Hook-1", IHook(hook1));
        moduleRegistry.registerProtocolHook("Hook-2", IHook(hook2));

        address[] memory hooksA = new address[](2);
        hooksA[0] = hook1;
        hooksA[1] = hook2;
        bytes[] memory hooksConfigA = new bytes[](1);
        hooksConfigA[0] = abi.encode("Hook1Config");
        address ipOrgOwner1 = address(0x789);
        IIPOrg ipOrg1 = new MockIPOrg(ipOrgOwner1);
        bytes32 registryKeyA = hookRegistry.hookRegistryKey(address(ipOrg1), "RelationshipType_A");
        vm.startPrank(ipOrgOwner1);
        vm.expectRevert(Errors.HookRegistry_HooksConfigLengthMismatch.selector);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyA, hooksA, hooksConfigA);
        vm.stopPrank();
    }

    function test_hookRegistry_revertRegisterZeroAddress() public {
        address hook1 = address(new MockBaseHook(address(accessControl)));
        address hook2 = address(0);
        moduleRegistry.registerProtocolHook("Hook-1", IHook(hook1));

        address[] memory hooksA = new address[](2);
        hooksA[0] = hook1;
        hooksA[1] = hook2;
        bytes[] memory hooksConfigA = new bytes[](2);
        hooksConfigA[0] = abi.encode("Hook1Config");
        hooksConfigA[1] = abi.encode("Hook2Config");
        address ipOrgOwner1 = address(0x789);
        IIPOrg ipOrg1 = new MockIPOrg(ipOrgOwner1);
        bytes32 registryKeyA = hookRegistry.hookRegistryKey(address(ipOrg1), "RelationshipType_A");
        vm.startPrank(ipOrgOwner1);
        vm.expectRevert(Errors.HookRegistry_RegisteringZeroAddressHook.selector);
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyA, hooksA, hooksConfigA);
        vm.stopPrank();
    }

    function test_hookRegistry_revertRegisterNonWhitelistedHook() public {
        address hook1 = address(new MockBaseHook(address(accessControl)));
        address hook2 = address(new MockBaseHook(address(accessControl)));

        address[] memory hooksA = new address[](2);
        hooksA[0] = hook1;
        hooksA[1] = hook2;
        bytes[] memory hooksConfigA = new bytes[](2);
        hooksConfigA[0] = abi.encode("Hook1Config");
        hooksConfigA[1] = abi.encode("Hook2Config");
        address ipOrgOwner1 = address(0x789);
        IIPOrg ipOrg1 = new MockIPOrg(ipOrgOwner1);
        bytes32 registryKeyA = hookRegistry.hookRegistryKey(address(ipOrg1), "RelationshipType_A");
        vm.startPrank(ipOrgOwner1);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.HookRegistry_RegisteringNonWhitelistedHook.selector,
                hook1)
        );
        hookRegistry.registerHooks(HookRegistry.HookType.PreAction, ipOrg1, registryKeyA, hooksA, hooksConfigA);
        vm.stopPrank();
    }

    function _generateHooks(uint256 numHooks) private returns (address[] memory, bytes[] memory) {
        address[] memory hooks = new address[](numHooks);
        bytes[] memory hooksConfig = new bytes[](numHooks);
        for(uint256 i = 0; i < numHooks; i++) {
            hooks[i] = address(new MockBaseHook(address(accessControl)));
            hooksConfig[i] = abi.encode("HookConfig-", i + 1);
            moduleRegistry.registerProtocolHook(string(abi.encodePacked("Hook-", i + 1)), IHook(hooks[i]));
        }
        return (hooks, hooksConfig);
    }
}
