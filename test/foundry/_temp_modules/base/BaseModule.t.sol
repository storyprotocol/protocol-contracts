// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/modules/base/BaseModule.sol";
import "test/foundry/mocks/MockBaseModule.sol";
import "test/foundry/mocks/MockIPOrg.sol";
import "contracts/lib/Errors.sol";


contract BaseModuleTest is Test {
    MockBaseModule module;
    address admin = address(123);
    IPAssetRegistry ipaRegistry = IPAssetRegistry(address(456));
    ModuleRegistry moduleRegistry = ModuleRegistry(address(789));
    MockIPOrg ipOrg;

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);

    function setUp() public {
        ipOrg = new MockIPOrg(admin);
        vm.prank(admin);
        module = new MockBaseModule(admin, BaseModule.ModuleConstruction(ipaRegistry, moduleRegistry, address(888)));
    }

    function test_baseModule_revert_constructorIpaRegistryIsZero() public {
        vm.prank(admin);
        vm.expectRevert(Errors.BaseModule_ZeroIpaRegistry.selector);
        new MockBaseModule(admin, BaseModule.ModuleConstruction(IPAssetRegistry(address(0)), moduleRegistry, address(888)));
    }

    function test_baseModule_revert_constructorModuleRegistryIsZero() public {
        vm.prank(admin);
        vm.expectRevert(Errors.BaseModule_ZeroModuleRegistry.selector);
        module = new MockBaseModule(admin, BaseModule.ModuleConstruction(ipaRegistry, ModuleRegistry(address(0)), address(888)));
    }

    function test_baseModule_setup() public {
        assertEq(address(module.IPA_REGISTRY()), address(ipaRegistry));
        assertEq(address(module.MODULE_REGISTRY()), address(moduleRegistry));
    }

    function test_baseModule_passesConfigParams() public {
        bytes memory params = abi.encode(uint256(123));
        module.configure(ipOrg, address(123), params);
        assertEq(module.callStackAt(0).caller, address(123));
        assertEq(module.callStackAt(0).params, params);
    }

    function test_baseModule_correctExecutionOrderAndParams() public {
        bytes memory params = abi.encode(uint256(123));
        vm.expectEmit(true, true, true, true);
        emit RequestCompleted(address(123));
        module.execute(ipOrg, address(123), params, new bytes[](0), new bytes[](0));
        assertEq(module.callStackAt(0).caller, address(123));
        assertEq(module.callStackAt(0).params, params);
        assertEq(module.callStackAt(0).ipOrg, address(ipOrg));
        assertEq(module.callStackAt(1).caller, address(123));
        assertEq(module.callStackAt(1).params, params);
        assertEq(module.callStackAt(1).ipOrg, address(ipOrg));
    }

    function test_baseModule_revertPreHookWrongParamsLength() public {
        bytes memory params = abi.encode(uint256(123));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.BaseModule_HooksParamsLengthMismatch.selector,
                uint8(HookRegistry.HookType.PreAction)
            )
        );
        module.execute(ipOrg, address(123), params, new bytes[](1), new bytes[](0));
    }

    function test_baseModule_revertPostHookWrongParamsLength() public {
        bytes memory params = abi.encode(uint256(123));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.BaseModule_HooksParamsLengthMismatch.selector,
                uint8(HookRegistry.HookType.PostAction)
            )
        );
        module.execute(ipOrg, address(123), params, new bytes[](0), new bytes[](1));
    }

    // TODO: hook execution tests, waiting for base hook


}
