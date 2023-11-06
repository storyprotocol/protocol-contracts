// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import 'test/foundry/utils/ProxyHelper.sol';
import 'test/foundry/utils/BaseTestUtils.sol';
import 'test/foundry/utils/AccessControlHelper.sol';
import "test/foundry/mocks/MockCollectNFT.sol";
import "test/foundry/mocks/MockCollectModule.sol";
import "contracts/StoryProtocol.sol";
import "contracts/ip-org/IPOrgFactory.sol";
import "contracts/ip-org/IPOrg.sol";
import "contracts/lib/IPOrgParams.sol";

import "contracts/IPAssetRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/errors/General.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/interfaces/modules/collect/ICollectModule.sol";

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";

// On active refactor
// import "contracts/modules/licensing/LicensingModule.sol";
// import "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
// import "contracts/modules/licensing/LicenseRegistry.sol";
// import '../mocks/MockTermsProcessor.sol';
// import { Licensing } from "contracts/lib/modules/Licensing.sol";

// TODO: Commented out contracts in active refactor. 
// Run tests from make lint, which will not run collect and license
contract BaseTest is BaseTestUtils, ProxyHelper, AccessControlHelper {

    IPOrg public ipOrg;
    address ipAssetOrgImpl;
    IPOrgFactory public ipOrgFactory;
    ModuleRegistry public moduleRegistry;
    // LicensingModule public licensingModule;
    // ILicenseRegistry public licenseRegistry;
    // MockTermsProcessor public nonCommercialTermsProcessor;
    // MockTermsProcessor public commercialTermsProcessor;
    ICollectModule public collectModule;
    RelationshipModule public relationshipModule;
    IPAssetRegistry public registry;
    StoryProtocol public spg;

    address public defaultCollectNftImpl;
    address public collectModuleImpl;

    address constant upgrader = address(6969);
    address constant ipAssetOrgOwner = address(456);
    address constant revoker = address(789);
    // string constant NON_COMMERCIAL_LICENSE_URI = "https://noncommercial.license";
    // string constant COMMERCIAL_LICENSE_URI = "https://commercial.license";

    constructor() {}

    function setUp() virtual override(BaseTestUtils) public {
        super.setUp();

        // Create Access Control
        _setupAccessControl();
        _grantRole(vm, AccessControl.UPGRADER_ROLE, upgrader);
        
        // Create IPAssetRegistry 
        registry = new IPAssetRegistry();

        // Create IPOrg Factory
        ipOrgFactory = new IPOrgFactory();
        address ipOrgFactoryImpl = address(new IPOrgFactory());
        ipOrgFactory = IPOrgFactory(
            _deployUUPSProxy(
                ipOrgFactoryImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))),
                    address(accessControl)
                )
            )
        );

        moduleRegistry = new ModuleRegistry(address(accessControl));
        spg = new StoryProtocol(ipOrgFactory, moduleRegistry);
        _grantRole(vm, AccessControl.IPORG_CREATOR_ROLE, address(spg));
        _grantRole(vm, AccessControl.MODULE_EXECUTOR_ROLE, address(spg));
        _grantRole(vm, AccessControl.MODULE_REGISTRAR_ROLE, address(this));

        // Create Relationship Module
        relationshipModule = new RelationshipModule(
            BaseModule.ModuleConstruction({
                ipaRegistry: registry,
                moduleRegistry: moduleRegistry,
                licenseRegistry: address(123)
            })
        );
        moduleRegistry.registerProtocolModule(ModuleRegistryKeys.RELATIONSHIP_MODULE, relationshipModule);
        
        // Create Licensing Module
        // address licensingImplementation = address(new LicensingModule(address(ipAssetOrgFactory)));
        // licensingModule = LicensingModule(
        //     _deployUUPSProxy(
        //         licensingImplementation,
        //         abi.encodeWithSelector(
        //             bytes4(keccak256(bytes("initialize(address,string)"))),
        //             address(accessControl), NON_COMMERCIAL_LICENSE_URI
        //         )
        //     )
        // );

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
        ipOrg = IPOrg(spg.registerIpOrg(ipAssetOrgParams));

        // licenseRegistry = ILicenseRegistry(ipOrg.getLicenseRegistry());

        // Configure Licensing for IPOrg
        // nonCommercialTermsProcessor = new MockTermsProcessor();
        // commercialTermsProcessor = new MockTermsProcessor();
        // licensingModule.configureIpOrgLicensing(address(ipOrg), _getLicensingConfig());

        vm.stopPrank();

    }

    // function _getLicensingConfig() view internal returns (Licensing.IPOrgConfig memory) {
    //     return Licensing.IPOrgConfig({
    //         nonCommercialConfig: Licensing.IpAssetConfig({
    //             canSublicense: true,
    //             ipAssetOrgRootLicenseId: 0
    //         }),
    //         nonCommercialTerms: Licensing.TermsProcessorConfig({
    //             processor: address(0), //nonCommercialTermsProcessor,
    //             data: abi.encode("nonCommercial")
    //         }),
    //         commercialConfig: Licensing.IpAssetConfig({
    //             canSublicense: false,
    //             ipAssetOrgRootLicenseId: 0
    //         }),
    //         commercialTerms: Licensing.TermsProcessorConfig({
    //             processor: address(0),// commercialTermsProcessor,
    //             data: abi.encode("commercial")
    //         }),
    //         rootIpAssetHasCommercialRights: false,
    //         revoker: revoker,
    //         commercialLicenseUri: "uriuri"
    //     });
    // }

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
        vm.prank(address(ipOrg));
        // TODO: This was commented for compilation
        // (uint256 id, ) = ipOrg.createIpAsset(IPAsset.CreateIpAssetParams({
        //     ipAssetType: IPAsset.IPAssetType(ipAssetType),
        //     name: "name",
        //     description: "description",
        //     mediaUrl: "mediaUrl",
        //     to: ipAssetOwner,
        //     parentIpAssetOrgId: 0,
        //     collectData: collectData
        // }));
        // return id;
        return 1;
    }

}
