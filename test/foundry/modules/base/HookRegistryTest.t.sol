// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/modules/base/HookRegistry.sol";
import "test/foundry/mocks/MockHookRegistry.sol";
import "contracts/lib/Errors.sol";

contract HookRegistryTest is Test {
    MockHookRegistry registry;
    address admin = address(123);

    event HooksRegistered(HookRegistry.HookType indexed hType, address[] indexed hook);
    event HooksCleared(HookRegistry.HookType indexed hType);

    function setUp() public {
        vm.prank(admin);
        registry = new MockHookRegistry();
    }

    function test_hookRegistry_registerPreHooks() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(456);
        vm.startPrank(admin);
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PreAction, hooks);
        registry.registerHooks(HookRegistry.HookType.PreAction, hooks);
        vm.stopPrank();
        assertEq(registry.hookAt(HookRegistry.HookType.PreAction, 0), hooks[0]);
        assertEq(registry.hookAt(HookRegistry.HookType.PreAction, 1), hooks[1]);
        assertEq(registry.totalHooks(HookRegistry.HookType.PreAction), hooks.length);
    }

    function test_hookRegistry_registerPreHooksClearsHooksIfNotEmpty() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(456);
        vm.startPrank(admin);
        registry.registerHooks(HookRegistry.HookType.PreAction, hooks);
        vm.expectEmit(true, false, false, true);
        emit HooksCleared(HookRegistry.HookType.PreAction);
        registry.registerHooks(HookRegistry.HookType.PreAction, hooks);
        vm.stopPrank();
        assertEq(registry.hookAt(HookRegistry.HookType.PreAction, 0), hooks[0]);
        assertEq(registry.hookAt(HookRegistry.HookType.PreAction, 1), hooks[1]);
        assertEq(registry.totalHooks(HookRegistry.HookType.PreAction), hooks.length);
    }

    function test_hookRegistry_registerPostHooks() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(456);
        vm.startPrank(admin);
        vm.expectEmit(true, false, false, true);
        emit HooksRegistered(HookRegistry.HookType.PostAction, hooks);
        registry.registerHooks(HookRegistry.HookType.PostAction, hooks);
        vm.stopPrank();
        assertEq(registry.hookAt(HookRegistry.HookType.PostAction, 0), hooks[0]);
        assertEq(registry.hookAt(HookRegistry.HookType.PostAction, 1), hooks[1]);
        assertEq(registry.totalHooks(HookRegistry.HookType.PostAction), hooks.length);
    }

    function test_hookRegistry_registerPostHooksClearsHooksIfNotEmpty() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(456);
        vm.startPrank(admin);
        registry.registerHooks(HookRegistry.HookType.PostAction, hooks);
        vm.expectEmit(true, false, false, true);
        emit HooksCleared(HookRegistry.HookType.PostAction);
        registry.registerHooks(HookRegistry.HookType.PostAction, hooks);
        vm.stopPrank();
        assertEq(registry.hookAt(HookRegistry.HookType.PostAction, 0), hooks[0]);
        assertEq(registry.hookAt(HookRegistry.HookType.PostAction, 1), hooks[1]);
        assertEq(registry.totalHooks(HookRegistry.HookType.PostAction), hooks.length);
    }

    function test_hookRegistry_revertRegisterHooksCallerNotAdmin() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(456);
        vm.expectRevert(Errors.HookRegistry_CallerNotAdmin.selector);
        registry.registerHooks(HookRegistry.HookType.PostAction, hooks);        
    }

    function test_hookRegistry_revertRegisterMaxHooksExceeded() public {
        address[] memory hooks = new address[](registry.MAX_HOOKS() + 1);
        vm.startPrank(admin);
        for(uint256 i = 0; i <= registry.MAX_HOOKS(); i++) {
            hooks[i] = vm.addr(i + 1);
        }
        vm.expectRevert(Errors.HookRegistry_MaxHooksExceeded.selector);
        registry.registerHooks(HookRegistry.HookType.PostAction, hooks);
        vm.expectRevert(Errors.HookRegistry_MaxHooksExceeded.selector);
        registry.registerHooks(HookRegistry.HookType.PreAction, hooks);
        vm.stopPrank();
    }

    function test_hookRegistry_revertRegisterDuplicatedHook() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(123);
        vm.startPrank(admin);
        vm.expectRevert(Errors.HookRegistry_RegisteringDuplicatedHook.selector);
        registry.registerHooks(HookRegistry.HookType.PostAction, hooks);
        vm.stopPrank();
    }

    function test_hookRegistry_getters() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(456);
        vm.startPrank(admin);

        registry.registerHooks(HookRegistry.HookType.PreAction, hooks);
        assertEq(registry.hookAt(HookRegistry.HookType.PreAction, 0), hooks[0]);
        assertEq(registry.hookAt(HookRegistry.HookType.PreAction, 1), hooks[1]);
        assertEq(registry.hookIndex(HookRegistry.HookType.PreAction, hooks[0]), 0);
        assertEq(registry.hookIndex(HookRegistry.HookType.PreAction, hooks[1]), 1);
        assertEq(registry.totalHooks(HookRegistry.HookType.PreAction), hooks.length);
        assertEq(registry.isRegistered(HookRegistry.HookType.PreAction, hooks[0]), true);
        assertEq(registry.isRegistered(HookRegistry.HookType.PreAction, hooks[1]), true);

        registry.registerHooks(HookRegistry.HookType.PostAction, hooks);
        assertEq(registry.hookAt(HookRegistry.HookType.PostAction, 0), hooks[0]);
        assertEq(registry.hookAt(HookRegistry.HookType.PostAction, 1), hooks[1]);
        assertEq(registry.hookIndex(HookRegistry.HookType.PostAction, hooks[0]), 0);
        assertEq(registry.hookIndex(HookRegistry.HookType.PostAction, hooks[1]), 1);
        assertEq(registry.totalHooks(HookRegistry.HookType.PostAction), hooks.length);
        assertEq(registry.isRegistered(HookRegistry.HookType.PostAction, hooks[0]), true);
        assertEq(registry.isRegistered(HookRegistry.HookType.PostAction, hooks[1]), true);

        vm.stopPrank();
    }

    function test_hookRegistry_clearPreHooks() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(456);
        vm.startPrank(admin);
        registry.registerHooks(HookRegistry.HookType.PreAction, hooks);
        vm.expectEmit(true, true, false, true);
        emit HooksCleared(HookRegistry.HookType.PreAction);
        registry.clearHooks(HookRegistry.HookType.PreAction);
        vm.stopPrank();
        assertEq(registry.hookIndex(HookRegistry.HookType.PreAction, hooks[0]), registry.INDEX_NOT_FOUND());
        assertEq(registry.hookIndex(HookRegistry.HookType.PreAction, hooks[1]), registry.INDEX_NOT_FOUND());
        assertEq(registry.totalHooks(HookRegistry.HookType.PreAction), 0);
    }

    function test_hookRegistry_clearPostHooks() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(456);
        vm.startPrank(admin);
        registry.registerHooks(HookRegistry.HookType.PostAction, hooks);
        vm.expectEmit(true, true, false, true);
        emit HooksCleared(HookRegistry.HookType.PostAction);
        registry.clearHooks(HookRegistry.HookType.PostAction);
        vm.stopPrank();
        assertEq(registry.hookIndex(HookRegistry.HookType.PostAction, hooks[0]), registry.INDEX_NOT_FOUND());
        assertEq(registry.hookIndex(HookRegistry.HookType.PostAction, hooks[1]), registry.INDEX_NOT_FOUND());
        assertEq(registry.totalHooks(HookRegistry.HookType.PostAction), 0);
    }

    function test_hookRegistry_revertClearHooksCallerNotAdmin() public {
        address[] memory hooks = new address[](2);
        hooks[0] = address(123);
        hooks[1] = address(456);
        vm.expectRevert(Errors.HookRegistry_CallerNotAdmin.selector);
        registry.registerHooks(HookRegistry.HookType.PostAction, hooks);        
    }

}
