/* solhint-disable contract-name-camelcase, func-name-mixedcase, var-name-mixedcase */
// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import { Errors } from "contracts/lib/Errors.sol";
import { IPOrg } from "contracts/ip-org/IPOrg.sol";
import { IPOrgController } from "contracts/ip-org/IPOrgController.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { LicenseRegistry } from "contracts/modules/licensing/LicenseRegistry.sol";
import { AccessControlSingleton } from "contracts/access-control/AccessControlSingleton.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { AccessControlHelper } from "../utils/AccessControlHelper.sol";
import { MockIPOrgController } from "../mocks/MockIPOrgController.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { RegistrationModule } from "contracts/modules/registration/RegistrationModule.sol";
import { REGISTRATION_MODULE_KEY } from "contracts/lib/modules/Module.sol";
import { LicensingFrameworkRepo } from "contracts/modules/licensing/LicensingFrameworkRepo.sol";
import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';
import 'test/foundry/utils/ProxyHelper.sol';
import "forge-std/Test.sol";

contract IPOrgControllerTest is Test, ProxyHelper, AccessControlHelper {
    using stdStorage for StdStorage;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event IPOrgRegistered(
        address owner,
        address ipAssetOrg,
        string name,
        string symbol,
        string[] ipAssetTypes
    );
    event IPOrgTransferred(address ipOrg, address prevOwner, address newOwner);
    event IPOrgPendingOwnerSet(address ipOrg, address pendingOwner);

    RegistrationModule public registrationModule;
    LicenseRegistry public licenseRegistry;
    IPAssetRegistry public registry;
    IPOrgController public ipOrgController;
    ModuleRegistry public moduleRegistry;
    LicensingFrameworkRepo public licensingFrameworkRepo;
    IPOrg public ipOrg;

    uint256 internal ipOrgOwnerPk = 0xa11ce;
    address payable internal ipOrgOwner = payable(vm.addr(ipOrgOwnerPk));

    address internal prevIpOrgOwner = vm.addr(0xbeef);
    address internal fakePrevIpOrgOwner = vm.addr(0xdead);
    address internal newIpOrgOwner = vm.addr(0xb0b);

    function setUp() public {
        _setupAccessControl();
        _grantRole(vm, AccessControl.IPORG_CREATOR_ROLE, ipOrgOwner);

        moduleRegistry = new ModuleRegistry(address(accessControl));
        registry = new IPAssetRegistry(address(moduleRegistry));
        address ipOrgControllerImpl = address(new IPOrgController(address(moduleRegistry)));
        ipOrgController = IPOrgController(
            _deployUUPSProxy(
                ipOrgControllerImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))),
                    address(accessControl)
                )
            )
        );
        _grantRole(vm, AccessControl.MODULE_EXECUTOR_ROLE, address(ipOrgController));

        licensingFrameworkRepo = new LicensingFrameworkRepo(address(accessControl));
        licenseRegistry = new LicenseRegistry(
            address(registry),
            address(moduleRegistry),
            address(licensingFrameworkRepo)
        );
        registrationModule = new RegistrationModule(
            BaseModule.ModuleConstruction({
                ipaRegistry: registry,
                moduleRegistry: moduleRegistry,
                licenseRegistry: licenseRegistry,
                ipOrgController: ipOrgController
            }),
            address(accessControl)
        );
        _grantRole(vm, AccessControl.MODULE_REGISTRAR_ROLE, address(this));
        moduleRegistry.registerProtocolModule(REGISTRATION_MODULE_KEY, registrationModule);

        vm.label(prevIpOrgOwner, "Prev IP Org Owner");
        vm.label(newIpOrgOwner, "New IP Org Owner");
        vm.label(fakePrevIpOrgOwner, "Fake Prev IP Org Owner");
    }

    function test_ipOrgController_registerIpOrg() public {
        vm.prank(ipOrgOwner);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(msg.sender, "name", "symbol", new string[](0)));
        assertTrue(ipOrgController.isIpOrg(address(ipOrg)));
    }

    function test_ipOrgController_revert_tooManyAssetTypes() public {
        uint256 maxAssetTypes = registrationModule.MAX_IP_ORG_ASSET_TYPES() + 1;
        string[] memory ipAssetTypes = new string[](maxAssetTypes);
        vm.expectRevert(Errors.RegistrationModule_TooManyAssetTypes.selector);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(msg.sender, "name", "symbol", ipAssetTypes));
    }

    function test_ipOrgController_revert_registerIpOrgZeroAddress() public {
        vm.expectRevert(Errors.ZeroAddress.selector);
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(address(0), "name", "symbol", ipAssetTypes));
    }

    function test_ipOrg_revert_initialize_Unauthorized() public {
        address ipOrg_ = Clones.clone(address(new IPOrg(address(this), address(moduleRegistry))));
        vm.prank(address(0));
        vm.expectRevert(Errors.Unauthorized.selector);
        IPOrg(ipOrg_).initialize(
            "name",
            "symbol"
        );
    }

    function test_ipOrg_mint() public {
        string[] memory ipAssetTypes = new string[](2);
        ipAssetTypes[0] = "type1";
        ipAssetTypes[1] = "type2";
        ipOrg = IPOrg(ipOrgController.registerIpOrg(msg.sender, "name", "symbol", ipAssetTypes));
        vm.startPrank(address(registrationModule));
        uint256 ipAssetId = ipOrg.mint(ipOrgOwner, 1);
        assertEq(ipOrg.ipOrgAssetType(ipAssetId), 1);
        assertEq(ipOrg.ownerOf(ipAssetId), ipOrgOwner);
        assertEq(ipOrg.totalSupply(), 1);
    }

    function test_ipOrg_revert_mintWhenNotRegistrationModule() public {
        string[] memory ipAssetTypes = new string[](2);
        ipAssetTypes[0] = "type1";
        ipAssetTypes[1] = "type2";
        ipOrg = IPOrg(ipOrgController.registerIpOrg(msg.sender, "name", "symbol", ipAssetTypes));
        vm.expectRevert(Errors.Unauthorized.selector);
        ipOrg.mint(ipOrgOwner, 1);
    }

    function test_ipOrg_burn() public {
        string[] memory ipAssetTypes = new string[](2);
        ipAssetTypes[0] = "type1";
        ipAssetTypes[1] = "type2";
        ipOrg = IPOrg(ipOrgController.registerIpOrg(msg.sender, "name", "symbol", ipAssetTypes));
        vm.startPrank(address(registrationModule));
        uint256 ipAssetId = ipOrg.mint(ipOrgOwner, 1);
        ipOrg.burn(ipAssetId);
        vm.stopPrank();
        vm.expectRevert(Errors.IPOrg_IdDoesNotExist.selector);
        ipOrg.ipOrgAssetType(ipAssetId);
        vm.expectRevert();
        ipOrg.ownerOf(ipAssetId);
    }

    function test_ipOrg_revert_burnWhenNotRegistrationModule() public {
        string[] memory ipAssetTypes = new string[](2);
        ipAssetTypes[0] = "type1";
        ipAssetTypes[1] = "type2";
        ipOrg = IPOrg(ipOrgController.registerIpOrg(msg.sender, "name", "symbol", ipAssetTypes));
        vm.prank(address(registrationModule));
        uint256 ipAssetId = ipOrg.mint(ipOrgOwner, 1);
        vm.prank(ipOrgOwner);
        vm.expectRevert(Errors.Unauthorized.selector);
        ipOrg.burn(ipAssetId);
    }

    function test_ipOrg_transferOwner() public {
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(msg.sender, "name", "symbol", ipAssetTypes));
        
        vm.expectEmit(address(ipOrgController));
        emit IPOrgPendingOwnerSet(address(ipOrg), newIpOrgOwner);
        vm.prank(msg.sender);
        ipOrgController.transferOwner(address(ipOrg), newIpOrgOwner);

        assertEq(ipOrgController.ownerOf(address(ipOrg)), msg.sender);
        assertEq(ipOrgController.pendingOwnerOf(address(ipOrg)), newIpOrgOwner);
    }

    function test_ipOrg_revert_transferOwnerInvalidIPOrgOwner() public {
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(prevIpOrgOwner, "name", "symbol", ipAssetTypes));
        
        vm.expectRevert(Errors.IPOrgController_InvalidIPOrgOwner.selector);
        vm.prank(fakePrevIpOrgOwner);
        ipOrgController.transferOwner(address(ipOrg), newIpOrgOwner);
    }

    function test_ipOrg_revert_transferOwnerInvalidNewIPOrgOwner() public {
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(prevIpOrgOwner, "name", "symbol", ipAssetTypes));
        
        vm.expectRevert(Errors.IPOrgController_InvalidNewIPOrgOwner.selector);
        vm.prank(prevIpOrgOwner);
        ipOrgController.transferOwner(address(ipOrg), address(0));
    }

    function test_ipOrg_cancelOwnerTransfer() public {
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(prevIpOrgOwner, "name", "symbol", ipAssetTypes));
        
        vm.expectEmit(address(ipOrgController));
        emit IPOrgPendingOwnerSet(address(ipOrg), newIpOrgOwner);
        vm.prank(prevIpOrgOwner);
        ipOrgController.transferOwner(address(ipOrg), newIpOrgOwner);

        vm.expectEmit(address(ipOrgController));
        emit IPOrgPendingOwnerSet(address(ipOrg), address(0));
        vm.prank(prevIpOrgOwner);
        ipOrgController.cancelOwnerTransfer(address(ipOrg));
    }

    function test_ipOrg_revert_cancelOwnerTransferInvalidIPOrgOwner() public {
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(prevIpOrgOwner, "name", "symbol", ipAssetTypes));
        
        vm.expectEmit(address(ipOrgController));
        emit IPOrgPendingOwnerSet(address(ipOrg), newIpOrgOwner);
        vm.prank(prevIpOrgOwner);
        ipOrgController.transferOwner(address(ipOrg), newIpOrgOwner);

        vm.expectRevert(Errors.IPOrgController_InvalidIPOrgOwner.selector);
        vm.prank(fakePrevIpOrgOwner);
        ipOrgController.cancelOwnerTransfer(address(ipOrg));
    }

    function test_ipOrg_revert_cancelOwnerTransferInvalidNewIPOrgOwner() public {
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(prevIpOrgOwner, "name", "symbol", ipAssetTypes));

        vm.expectRevert(Errors.IPOrgController_OwnerTransferUninitialized.selector);
        vm.prank(prevIpOrgOwner);
        ipOrgController.cancelOwnerTransfer(address(ipOrg));
    }

    function test_ipOrg_acceptOwnerTransfer() public {
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(prevIpOrgOwner, "name", "symbol", ipAssetTypes));
        
        vm.expectEmit(address(ipOrgController));
        emit IPOrgPendingOwnerSet(address(ipOrg), newIpOrgOwner);
        vm.prank(prevIpOrgOwner);
        ipOrgController.transferOwner(address(ipOrg), newIpOrgOwner);

        vm.expectEmit(address(ipOrgController));
        emit IPOrgPendingOwnerSet(address(ipOrg), address(0));
        vm.expectEmit(address(ipOrgController));
        emit IPOrgTransferred(address(ipOrg), prevIpOrgOwner, newIpOrgOwner);
        vm.prank(newIpOrgOwner);
        ipOrgController.acceptOwnerTransfer(address(ipOrg));
    }

    function test_ipOrg_revert_acceptOwnerTransferInvalidIPOrgOwner() public {
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(prevIpOrgOwner, "name", "symbol", ipAssetTypes));
        
        vm.expectEmit(address(ipOrgController));
        emit IPOrgPendingOwnerSet(address(ipOrg), newIpOrgOwner);
        vm.prank(prevIpOrgOwner);
        ipOrgController.transferOwner(address(ipOrg), newIpOrgOwner);

        vm.expectRevert(Errors.IPOrgController_InvalidIPOrgOwner.selector);
        vm.prank(prevIpOrgOwner);
        ipOrgController.acceptOwnerTransfer(address(ipOrg));
    }
}
