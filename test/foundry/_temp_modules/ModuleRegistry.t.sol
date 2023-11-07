// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/modules/base/BaseModule.sol";
import "test/foundry/utils/AccessControlHelper.sol";
import "test/foundry/mocks/MockBaseModule.sol";
import "contracts/lib/Errors.sol";
import "contracts/modules/ModuleRegistry.sol";

// Todo: test events
contract ModuleRegistryTest is Test, AccessControlHelper {
    ModuleRegistry registry;

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);

    function setUp() public {
        _setupAccessControl();
        _grantRole(vm, AccessControl.MODULE_REGISTRAR_ROLE, admin);
        registry = new ModuleRegistry(address(accessControl));
    }

    function test_moduleRegistry_addProtocolModule() public {
        BaseModule.ModuleConstruction memory moduleConstruction = BaseModule.ModuleConstruction(
            IPAssetRegistry(address(0x123)),
            ModuleRegistry(address(0x983)),
            address(0x123)
        );
        MockBaseModule module = new MockBaseModule(admin, moduleConstruction);
        vm.prank(admin);
        registry.registerProtocolModule("test", module);
        assertEq(address(registry.moduleForKey("test")), address(module));
    }
    
    function test_moduleRegistry_removeProtocolModule() public {
        BaseModule.ModuleConstruction memory moduleConstruction = BaseModule.ModuleConstruction(
            IPAssetRegistry(address(0x123)),
            ModuleRegistry(address(0x983)),
            address(0x123)
        );
        MockBaseModule module = new MockBaseModule(admin, moduleConstruction);
        vm.startPrank(admin);
        registry.registerProtocolModule("test", module);
        assertEq(address(registry.moduleForKey("test")), address(module));
        registry.removeProtocolModule("test");
        assertEq(address(registry.moduleForKey("test")), address(0));
        vm.stopPrank();
    }
}
