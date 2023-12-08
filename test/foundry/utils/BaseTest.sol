// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import 'test/foundry/utils/ProxyHelper.sol';
import 'test/foundry/utils/BaseTestUtils.sol';
import 'test/foundry/utils/AccessControlHelper.sol';
import "contracts/StoryProtocol.sol";
import "contracts/ip-org/IPOrgController.sol";
import "contracts/ip-org/IPOrg.sol";
import "contracts/lib/IPOrgParams.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/lib/modules/Registration.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/modules/licensing/LicenseRegistry.sol";
import "contracts/modules/licensing/LicensingModule.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { LICENSING_MODULE_KEY, RELATIONSHIP_MODULE_KEY, REGISTRATION_MODULE_KEY } from "contracts/lib/modules/Module.sol";
import { IGateway } from "contracts/interfaces/modules/IGateway.sol";
import { RegistrationModule } from "contracts/modules/registration/RegistrationModule.sol";
import { LicensingFrameworkRepo } from "contracts/modules/licensing/LicensingFrameworkRepo.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";

contract BaseTest is BaseTestUtils, ProxyHelper, AccessControlHelper {
    using ShortStrings for *;

    IPOrg public ipOrg;
    IPOrgController public ipOrgController;
    ModuleRegistry public moduleRegistry;
    RelationshipModule public relationshipModule;
    IPAssetRegistry public registry;
    StoryProtocol public spg;
    LicensingFrameworkRepo public licensingFrameworkRepo;
    LicensingModule public licensingModule;
    LicenseRegistry public licenseRegistry;
    RegistrationModule public registrationModule;

    address constant upgrader = address(6969);
    address constant ipOrgOwner = address(456);
    address constant relManager = address(9999);
    address constant licensingManager = address(333);
    address constant defaultRevoker = address(555);

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
        licensingFrameworkRepo = new LicensingFrameworkRepo(address(accessControl));
        _grantRole(vm, AccessControl.LICENSING_MANAGER, licensingManager);

        licenseRegistry = new LicenseRegistry(
            address(registry),
            address(moduleRegistry),
            address(licensingFrameworkRepo)
        );
        licensingModule = new LicensingModule(
            BaseModule.ModuleConstruction({
                ipaRegistry: registry,
                moduleRegistry: moduleRegistry,
                licenseRegistry: licenseRegistry,
                ipOrgController: ipOrgController
            }),
            address(licensingFrameworkRepo),
            defaultRevoker
        );
        moduleRegistry.registerProtocolModule(LICENSING_MODULE_KEY, licensingModule);

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
        moduleRegistry.registerProtocolModule(REGISTRATION_MODULE_KEY, registrationModule);

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
        moduleRegistry.registerProtocolModule(RELATIONSHIP_MODULE_KEY, relationshipModule);

        // moduleRegistry.registerProtocolGateway(IGateway(spg));
        IPOrgParams.RegisterIPOrgParams memory ipAssetOrgParams = IPOrgParams.RegisterIPOrgParams(
            address(registry),
            "IPOrgName",
            "FRN",
            "description",
            "tokenURI"
        );

        vm.startPrank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](3);
        ipAssetTypes[0] = "CHARACTER";
        ipAssetTypes[1] = "STORY";
        ipAssetTypes[2] = "LOCATION";
        ipOrg = IPOrg(spg.registerIpOrg(
            ipOrgOwner,
            ipAssetOrgParams.name,
            ipAssetOrgParams.symbol,
            ipAssetTypes
        ));


        vm.stopPrank();

    }

    /// @dev Helper function for creating an IP asset for an owner and IP type.
    ///      TO-DO: Replace this with a simpler set of default owners that get
    ///      tested against. The reason this is currently added is that during
    ///      fuzz testing, foundry may plug existing contracts as potential
    ///      owners for IP asset creation.
    function _createIpAsset(
        address ipAssetOwner,
        uint8 ipOrgAssetType,
        bytes memory collectData
    ) internal isValidReceiver(ipAssetOwner) returns (uint256 globalId, uint256 localId) {
        // vm.assume(ipAssetType > uint8(type(IPAsset.IPAssetType).min));
        // vm.assume(ipAssetType < uint8(type(IPAsset.IPAssetType).max));
        vm.prank(address(ipAssetOwner));
        Registration.RegisterIPAssetParams memory params = Registration.RegisterIPAssetParams({
            owner: ipAssetOwner,
            name: "TestIPAsset",
            ipOrgAssetType: ipOrgAssetType, 
            hash: "",
            mediaUrl: ""
        });
        bytes[] memory hooks = new bytes[](0);
        return spg.registerIPAsset(address(ipOrg), params, 0, hooks, hooks);
    }

    function _createIpAssetAndLinkLicense(
        address ipAssetOwner,
        uint8 ipOrgAssetType,
        uint256 licenseId,
        bytes memory collectData
    ) internal isValidReceiver(ipAssetOwner) returns (uint256 globalId, uint256 localId) {
        // vm.assume(ipAssetType > uint8(type(IPAsset.IPAssetType).min));
        // vm.assume(ipAssetType < uint8(type(IPAsset.IPAssetType).max));
        vm.prank(address(ipAssetOwner));
        Registration.RegisterIPAssetParams memory params = Registration.RegisterIPAssetParams({
            owner: ipAssetOwner,
            name: "TestIPAsset",
            ipOrgAssetType: ipOrgAssetType,
            hash: "",
            mediaUrl: ""
        });
        bytes[] memory hooks = new bytes[](0);
        return spg.registerIPAsset(address(ipOrg), params, licenseId, hooks, hooks);
    }

    function _deployHook(bytes memory code_, uint256 hookTypeFlag_, uint256 seed_) internal returns (address hookAddr) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(seed_)));
        for (uint256 i = 0; i < 1500; i++) {
            bytes32 salt = bytes32(randomNumber + i);
            bytes32 bytecodeHash = keccak256(code_);
            address expectedAddress = Create2.computeAddress(salt, bytecodeHash);
            uint160 prefix = hookTypeFlag_ == Hook.SYNC_FLAG ? 0x02 : 0x01;
            if (_doesAddressStartWith(expectedAddress, prefix)) {
                hookAddr = Create2.deploy(0, salt, code_);
                return hookAddr;
            }
        }
    }

    function _doesAddressStartWith(address address_,uint160 prefix_) private pure returns (bool) {
        return uint160(address_) >> (160 - 2) == prefix_;
    }
}
