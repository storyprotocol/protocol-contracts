// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/modules/base/BaseModule.sol";
import "test/foundry/utils/AccessControlHelper.sol";
import "test/foundry/mocks/MockBaseModule.sol";
import "test/foundry/mocks/MockBaseHook.sol";
import "contracts/ip-org/IPOrgController.sol";
import "contracts/lib/Errors.sol";
import "contracts/modules/ModuleRegistry.sol";
import { MockGateway } from "test/foundry/mocks/MockGateway.sol";
import { ModuleKey } from "contracts/lib/modules/Module.sol";

contract ModuleRegistryTest is Test, AccessControlHelper {

    ModuleKey constant UNREGISTERED_MODULE = ModuleKey.wrap(keccak256(abi.encodePacked("unregistered_module_key")));
    ModuleKey constant TEST_MODULE = ModuleKey.wrap(keccak256(abi.encodePacked("test")));
    ModuleRegistry registry;
    MockGateway gateway;

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);

    event ModuleAuthorizationGranted(
        ModuleKey indexed key,
        bytes4 fn,
        address indexed gateway,
        bool grant
    );

    event ModuleAdded(
        address indexed ipOrg,
        string moduleKey,
        address indexed module
    );

    event ModuleRemoved(
        ModuleKey indexed key,
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
        gateway = new MockGateway(true, registry);
    }

    function test_moduleRegistry_registerProtocolGateway() public {
        BaseModule.ModuleConstruction memory moduleConstruction = BaseModule.ModuleConstruction(
            IPAssetRegistry(address(0x123)),
            ModuleRegistry(address(0x983)),
            LicenseRegistry(address(0x123)),
            IPOrgController(address(0x123))
        );
        MockBaseModule module = new MockBaseModule(admin, moduleConstruction);
        vm.startPrank(admin);
        registry.registerProtocolModule(TEST_MODULE, module);
        vm.expectEmit(address(registry));
        emit ModuleAuthorizationGranted(TEST_MODULE, MockBaseModule.test.selector, address(gateway), true);
        registry.registerProtocolGateway(gateway);
        assertTrue(registry.isAuthorized(TEST_MODULE, gateway, MockBaseModule.test.selector));
    }

    function test_moduleRegistry_removeProtocolGateway() public {
        BaseModule.ModuleConstruction memory moduleConstruction = BaseModule.ModuleConstruction(
            IPAssetRegistry(address(0x123)),
            ModuleRegistry(address(0x983)),
            LicenseRegistry(address(0x123)),
            IPOrgController(address(0x123))
        );
        MockBaseModule module = new MockBaseModule(admin, moduleConstruction);
        vm.startPrank(admin);
        registry.registerProtocolModule(TEST_MODULE, module);
        registry.registerProtocolGateway(gateway);
        vm.expectEmit(address(registry));
        emit ModuleAuthorizationGranted(TEST_MODULE, MockBaseModule.test.selector, address(gateway), false);
        registry.removeProtocolGateway(gateway);
        assertFalse(registry.isAuthorized(TEST_MODULE, gateway, MockBaseModule.test.selector));
    }

    function test_moduleRegistry_revert_registerInvalidGateway() public {
        vm.startPrank(admin);
        gateway.setIsValid(false);
        vm.expectRevert(Errors.ModuleRegistry_InvalidGateway.selector);
        registry.registerProtocolGateway(gateway);
    }

    function test_moduleRegistry_revert_registerGatewayUnregisteredModule() public {
        vm.startPrank(admin);
        vm.expectRevert(Errors.ModuleRegistry_ModuleNotYetRegistered.selector);
        registry.registerProtocolGateway(gateway);
    }

    function test_moduleRegistry_revert_registerGatewayDuplicateDependency() public {
        BaseModule.ModuleConstruction memory moduleConstruction = BaseModule.ModuleConstruction(
            IPAssetRegistry(address(0x123)),
            ModuleRegistry(address(0x983)),
            LicenseRegistry(address(0x123)),
            IPOrgController(address(0x123))
        );
        MockBaseModule module = new MockBaseModule(admin, moduleConstruction);
        vm.startPrank(admin);
        registry.registerProtocolModule(TEST_MODULE, module);
        registry.registerProtocolGateway(gateway);
        vm.expectRevert(Errors.ModuleRegistry_DependencyAlreadyRegistered.selector);
        registry.registerProtocolGateway(gateway);
    }

    function test_moduleRegistry_revert_removeUnregisteredGateway() public {
        vm.startPrank(admin);
        vm.expectRevert(Errors.ModuleRegistry_DependencyNotYetRegistered.selector);
        registry.removeProtocolGateway(gateway);
    }

    function test_moduleRegistry_revert_removeInvalidGateway() public {
        BaseModule.ModuleConstruction memory moduleConstruction = BaseModule.ModuleConstruction(
            IPAssetRegistry(address(0x123)),
            ModuleRegistry(address(0x983)),
            LicenseRegistry(address(0x123)),
            IPOrgController(address(0x123))
        );
        MockBaseModule module = new MockBaseModule(admin, moduleConstruction);
        vm.startPrank(admin);
        registry.registerProtocolModule(TEST_MODULE, module);
        registry.registerProtocolGateway(gateway);
        gateway.setIsValid(false);
        vm.expectRevert(Errors.ModuleRegistry_InvalidGateway.selector);
        registry.removeProtocolGateway(gateway);
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
        emit ModuleAdded(address(0), string(abi.encodePacked(TEST_MODULE)), address(module));
        vm.prank(admin);
        registry.registerProtocolModule(TEST_MODULE, module);

        assertEq(address(registry.protocolModule(TEST_MODULE)), address(module));
    }

    function test_moduleRegistry_revert_addProtocolModuleZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        vm.prank(admin);
        registry.registerProtocolModule(TEST_MODULE, BaseModule(address(0)));

        assertEq(address(registry.protocolModule(TEST_MODULE)), address(0));
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
        emit ModuleAdded(address(0), string(abi.encodePacked(TEST_MODULE)), address(module));
        registry.registerProtocolModule(TEST_MODULE, module);
        assertEq(address(registry.protocolModule(TEST_MODULE)), address(module));

        vm.expectEmit(address(registry));
        emit ModuleRemoved(TEST_MODULE, address(module));
        registry.removeProtocolModule(TEST_MODULE);
        assertEq(address(registry.protocolModule(TEST_MODULE)), address(0));

        vm.stopPrank();
    }

    function test_moduleRegistry_revert_removeProtocolModuleModuleNotYetRegistered() public {
        vm.expectRevert(Errors.ModuleRegistry_ModuleNotYetRegistered.selector);
        vm.prank(admin);
        registry.removeProtocolModule(UNREGISTERED_MODULE);
        assertEq(address(registry.protocolModule(UNREGISTERED_MODULE)), address(0));
    }

    function test_moduleRegistry_revert_configureModuleNotYetRegistered() public {
        bytes memory encodedParams = abi.encode("test");
        vm.expectRevert(Errors.ModuleRegistry_ModuleNotYetRegistered.selector);
        registry.configure(
            IIPOrg(address(0x123)),
            "unregistered_module_key",
            encodedParams
        );
    }

    function test_moduleRegistry_addProtocolHook() public {
        MockBaseHook hook = new MockBaseHook(address(accessControl));
        vm.prank(admin);
        registry.registerProtocolHook("test", hook);
        assertEq(address(registry.hookForKey("test")), address(hook));
        assertEq(registry.isRegisteredHook(hook), true);
    }

    function test_moduleRegistry_removeProtocolHook() public {
        MockBaseHook hook = new MockBaseHook(address(accessControl));
        vm.startPrank(admin);
        registry.registerProtocolHook("test", hook);
        assertEq(address(registry.hookForKey("test")), address(hook));
        registry.removeProtocolHook("test");
        assertEq(address(registry.hookForKey("test")), address(0));
        assertEq(registry.isRegisteredHook(hook), false);
        vm.stopPrank();
    }
}
