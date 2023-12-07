// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/modules/base/BaseModule.sol";
import "test/foundry/utils/AccessControlHelper.sol";
import "test/foundry/mocks/MockBaseModule.sol";
import "contracts/ip-org/IPOrgController.sol";
import "contracts/lib/Errors.sol";
import "contracts/modules/ModuleRegistry.sol";

// Todo: test events
contract ModuleRegistryTest is Test, AccessControlHelper {
    ModuleRegistry registry;

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);

    event ModuleAdded(
        address indexed ipOrg,
        string moduleKey,
        address indexed module
    );
    event ModuleRemoved(
        address indexed ipOrg,
        string moduleKey,
        address indexed module
    );
    event ModuleConfigured(
        address indexed ipOrg,
        string moduleKey,
        address indexed caller,
        bytes params
    );

    function setUp() public {
        _setupAccessControl();
        _grantRole(vm, AccessControl.MODULE_REGISTRAR_ROLE, admin);
        registry = new ModuleRegistry(address(accessControl));
    }

    function test_moduleRegistry_addProtocolModule() public {
        BaseModule.ModuleConstruction memory moduleConstruction = BaseModule.ModuleConstruction(
            IPAssetRegistry(address(0x123)),
            ModuleRegistry(address(0x983)),
            LicenseRegistry(address(0x123)),
            IPOrgController(address(0x123))
        );
        MockBaseModule module = new MockBaseModule(admin, moduleConstruction);
        
        vm.expectEmit(address(registry));
        emit ModuleAdded(registry.PROTOCOL_LEVEL(), "test", address(module));
        vm.prank(admin);
        registry.registerProtocolModule("test", module);

        assertEq(address(registry.moduleForKey("test")), address(module));
    }

    function test_moduleRegistry_revert_addProtocolModuleZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        vm.prank(admin);
        registry.registerProtocolModule("test", BaseModule(address(0)));

        assertEq(address(registry.moduleForKey("test")), address(0));
    }
    
    function test_moduleRegistry_removeProtocolModule() public {
        BaseModule.ModuleConstruction memory moduleConstruction = BaseModule.ModuleConstruction(
            IPAssetRegistry(address(0x123)),
            ModuleRegistry(address(0x983)),
            LicenseRegistry(address(0x123)),
            IPOrgController(address(0x123))
        );
        MockBaseModule module = new MockBaseModule(admin, moduleConstruction);
        vm.startPrank(admin);

        vm.expectEmit(address(registry));
        emit ModuleAdded(registry.PROTOCOL_LEVEL(), "test", address(module));
        registry.registerProtocolModule("test", module);
        assertEq(address(registry.moduleForKey("test")), address(module));

        vm.expectEmit(address(registry));
        emit ModuleRemoved(registry.PROTOCOL_LEVEL(), "test", address(module));
        registry.removeProtocolModule("test");
        assertEq(address(registry.moduleForKey("test")), address(0));

        vm.stopPrank();
    }

    function test_moduleRegistry_revert_removeProtocolModuleModuleNotRegistered() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ModuleRegistry_ModuleNotRegistered.selector,
                "unregistered_module_key"
            )
        );
        vm.prank(admin);
        registry.removeProtocolModule("unregistered_module_key");
        assertEq(address(registry.moduleForKey("unregistered_module_key")), address(0));
    }

    function test_moduleRegistry_revert_configureModuleNotRegistered() public {
        bytes memory encodedParams = abi.encode("test");
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.ModuleRegistry_ModuleNotRegistered.selector,
                "unregistered_module_key"
            )
        );
        registry.configure(
            IIPOrg(address(0x123)),
            "unregistered_module_key",
            encodedParams
        );
    }
}
