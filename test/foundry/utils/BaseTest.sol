// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import 'test/foundry/utils/ProxyHelper.sol';
import 'test/foundry/utils/BaseTestUtils.sol';
import 'test/foundry/utils/AccessControlHelper.sol';
import "test/foundry/mocks/MockCollectNFT.sol";
import "test/foundry/mocks/MockCollectModule.sol";
import "contracts/StoryProtocol.sol";
import "contracts/ip-org/IPOrgController.sol";
import "contracts/ip-org/IPOrg.sol";
import "contracts/lib/IPOrgParams.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/lib/modules/Registration.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/interfaces/modules/collect/ICollectModule.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/modules/licensing/LicenseRegistry.sol";
import "contracts/modules/licensing/LicenseCreatorModule.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { RegistrationModule } from "contracts/modules/registration/RegistrationModule.sol";

contract BaseTest is BaseTestUtils, ProxyHelper, AccessControlHelper {
    using ShortStrings for *;

    IPOrg public ipOrg;
    IPOrgController public ipOrgController;
    ModuleRegistry public moduleRegistry;
    ICollectModule public collectModule;
    RelationshipModule public relationshipModule;
    IPAssetRegistry public registry;
    StoryProtocol public spg;
    LicenseCreatorModule public licensingModule;
    LicenseRegistry public licenseRegistry;
    RegistrationModule public registrationModule;

    address public defaultCollectNftImpl;
    address public collectModuleImpl;

    address constant upgrader = address(6969);
    address constant ipAssetOrgOwner = address(456);
    address constant relManager = address(9999);

    function setUp() virtual override(BaseTestUtils) public {
        super.setUp();

        // Create Access Control
        _setupAccessControl();
        _grantRole(vm, AccessControl.UPGRADER_ROLE, upgrader);
        
        // Setup module registry
        moduleRegistry = new ModuleRegistry(address(accessControl));

        // Create IPAssetRegistry 
        registry = new IPAssetRegistry(address(moduleRegistry));

        // Create IPOrgController
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

        spg = new StoryProtocol(ipOrgController, moduleRegistry);
        _grantRole(vm, AccessControl.IPORG_CREATOR_ROLE, address(spg));
        _grantRole(vm, AccessControl.MODULE_EXECUTOR_ROLE, address(spg));
        _grantRole(vm, AccessControl.MODULE_EXECUTOR_ROLE, address(address(ipOrgController)));
        _grantRole(vm, AccessControl.MODULE_REGISTRAR_ROLE, address(this));

        // Create Licensing contracts
        licenseRegistry = new LicenseRegistry(address(registry), address(moduleRegistry));
        licensingModule = new LicenseCreatorModule(
            BaseModule.ModuleConstruction({
                ipaRegistry: registry,
                moduleRegistry: moduleRegistry,
                licenseRegistry: licenseRegistry,
                ipOrgController: ipOrgController
            })
        );
        moduleRegistry.registerProtocolModule(ModuleRegistryKeys.LICENSING_MODULE, licensingModule);

        // Create Registration Module
        registrationModule = new RegistrationModule(
            BaseModule.ModuleConstruction({
                ipaRegistry: registry,
                moduleRegistry: moduleRegistry,
                licenseRegistry: licenseRegistry,
                ipOrgController: ipOrgController
            }),
            address(accessControl)
        );
        moduleRegistry.registerProtocolModule(ModuleRegistryKeys.REGISTRATION_MODULE, registrationModule);

        // Create Relationship Module
        relationshipModule = new RelationshipModule(
            BaseModule.ModuleConstruction({
                ipaRegistry: registry,
                moduleRegistry: moduleRegistry,
                licenseRegistry: licenseRegistry,
                ipOrgController: ipOrgController
            }),
            address(accessControl)
        );
        moduleRegistry.registerProtocolModule(ModuleRegistryKeys.RELATIONSHIP_MODULE, relationshipModule);


        defaultCollectNftImpl = _deployCollectNFTImpl();
        collectModule = ICollectModule(_deployCollectModule(defaultCollectNftImpl));

        IPOrgParams.RegisterIPOrgParams memory ipAssetOrgParams = IPOrgParams.RegisterIPOrgParams(
            address(registry),
            "IPOrgName",
            "FRN",
            "description",
            "tokenURI"
        );

        vm.startPrank(ipAssetOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(spg.registerIpOrg(
            ipAssetOrgOwner,
            ipAssetOrgParams.name,
            ipAssetOrgParams.symbol,
            ipAssetTypes
        ));


        vm.stopPrank();

    }

    function _deployCollectNFTImpl() internal virtual returns (address) {
        return address(new MockCollectNFT());
    }

    function _deployCollectModule(address collectNftImpl) internal virtual returns (address) {
        collectModuleImpl = address(new MockCollectModule(address(registry), collectNftImpl));
        return _deployUUPSProxy(
                collectModuleImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
        );
    }

    /// @dev Helper function for creating an IP asset for an owner and IP type.
    ///      TO-DO: Replace this with a simpler set of default owners that get
    ///      tested against. The reason this is currently added is that during
    ///      fuzz testing, foundry may plug existing contracts as potential
    ///      owners for IP asset creation.
    function _createIpAsset(address ipAssetOwner, uint8 ipAssetType, bytes memory collectData) internal isValidReceiver(ipAssetOwner) returns (uint256) {
        // vm.assume(ipAssetType > uint8(type(IPAsset.IPAssetType).min));
        // vm.assume(ipAssetType < uint8(type(IPAsset.IPAssetType).max));
        vm.prank(address(ipAssetOwner));
        Registration.RegisterIPAssetParams memory params = Registration.RegisterIPAssetParams({
            owner: ipAssetOwner,
            name: "TestIPAsset",
            ipAssetType: 0, 
            hash: ""
        });
        bytes[] memory hooks = new bytes[](0);
        (uint256 globalId, uint256 localId) = spg.registerIPAsset(address(ipOrg), params, hooks, hooks);
        return globalId;
    }

}
