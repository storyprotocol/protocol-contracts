// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/modules/base/HookRegistry.sol";
import "test/foundry/mocks/MockHookRegistry.sol";
import "contracts/lib/Errors.sol";

contract HookRegistryTest is Test {
    MockHookRegistry registry;
    address admin = address(123);

    event HookRegistered(HookRegistry.HookType indexed hType, address indexed hook, uint256 index);
    event HookUnregistered(HookRegistry.HookType indexed hType, address indexed hook, uint256 index);
    event HookReplaced(
        HookRegistry.HookType hType,
        address indexed prevHook,
        uint256 prevIndex,
        address indexed nextHook,
        uint256 nextIndex
    );

    function setUp() public {
        vm.prank(admin);
        registry = new MockHookRegistry();
    }

    function test_hookRegistry_registerPreHooks() public {
        address hook1 = address(456);
        address hook2 = address(789);
        vm.startPrank(admin);
        vm.expectEmit(true, true, false, true);
        emit HookRegistered(HookRegistry.HookType.PreAction, hook1, 0);
        registry.registerHook(HookRegistry.HookType.PreAction, hook1);
        vm.expectEmit(true, true, false, true);
        emit HookRegistered(HookRegistry.HookType.PreAction, hook2, 1);
        registry.registerHook(HookRegistry.HookType.PreAction, hook2);
        vm.stopPrank();
        assertEq(registry.hookAt(HookRegistry.HookType.PreAction, 0), hook1);
        assertEq(registry.hookAt(HookRegistry.HookType.PreAction, 1), hook2);
        assertEq(registry.totalHooks(HookRegistry.HookType.PreAction), 2);
    }

    function test_hookRegistry_registerPostHooks() public {
        address hook1 = address(456);
        address hook2 = address(789);
        vm.startPrank(admin);
        vm.expectEmit(true, true, false, true);
        emit HookRegistered(HookRegistry.HookType.PostAction, hook1, 0);
        registry.registerHook(HookRegistry.HookType.PostAction, hook1);
        vm.expectEmit(true, true, false, true);
        emit HookRegistered(HookRegistry.HookType.PostAction, hook2, 1);
        registry.registerHook(HookRegistry.HookType.PostAction, hook2);
        vm.stopPrank();
        assertEq(registry.hookAt(HookRegistry.HookType.PostAction, 0), hook1);
        assertEq(registry.hookAt(HookRegistry.HookType.PostAction, 1), hook2);
        assertEq(registry.totalHooks(HookRegistry.HookType.PostAction), 2);
    }

    function test_hookRegistry_revertRegisterPreHooksCallerNotAdmin() public {
        address hook1 = address(456);
        vm.expectRevert(Errors.HookRegistry_CallerNotAdmin.selector);
        registry.registerHook(HookRegistry.HookType.PostAction, hook1);        
    }

    function test_hookRegistry_revertRegisterTooManyHooks() public {
        vm.startPrank(admin);
        for(uint256 i = 0; i <= registry.MAX_HOOKS(); i++) {
            if (i == registry.MAX_HOOKS()) {
                vm.expectRevert(Errors.HookRegistry_MaxHooksExceeded.selector);
            }
            registry.registerHook(HookRegistry.HookType.PostAction, vm.addr(i + 1));
        }
    }

    function test_hookRegistry_revertRegisterHookAlreadyRegistered() public {
        address hook1 = address(456);
        vm.startPrank(admin);
        registry.registerHook(HookRegistry.HookType.PostAction, hook1);
        vm.expectRevert(Errors.HookRegistry_AlreadyRegistered.selector);
        registry.registerHook(HookRegistry.HookType.PostAction, hook1);
        vm.stopPrank();
    }
    


}
