// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import 'test/foundry/utils/ProxyHelper.sol';
import 'test/foundry/utils/BaseTestUtils.sol';
import "test/foundry/mocks/RelationshipModuleHarness.sol";
import "test/foundry/mocks/MockCollectNFT.sol";
import "test/foundry/mocks/MockCollectModule.sol";
import "contracts/ip-org/IPOrgFactory.sol";
import "contracts/ip-org/IPOrg.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/lib/IPAsset.sol";
import "contracts/errors/General.sol";
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
import "contracts/modules/relationships/processors/DstOwnerRelationshipProcessor.sol";
import "contracts/modules/relationships/RelationshipModuleBase.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/interfaces/modules/collect/ICollectModule.sol";

import { AccessControl } from "contracts/lib/AccessControl.sol";

// On active refactor
// import "contracts/modules/licensing/LicensingModule.sol";
// import "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
// import "contracts/modules/licensing/LicenseRegistry.sol";
// import '../mocks/MockTermsProcessor.sol';
// import { Licensing } from "contracts/lib/modules/Licensing.sol";

// TODO: Commented out contracts in active refactor. 
// Run tests from make lint, which will not run collect and license
contract BaseTest is BaseTestUtils, ProxyHelper {

    IPOrg public ipAssetOrg;
    address ipAssetOrgImpl;
    IPOrgFactory public ipAssetOrgFactory;
    RelationshipModuleBase public relationshipModule;
    AccessControlSingleton accessControl;
    PermissionlessRelationshipProcessor public relationshipProcessor;
    DstOwnerRelationshipProcessor public dstOwnerRelationshipProcessor;
    // LicensingModule public licensingModule;
    // ILicenseRegistry public licenseRegistry;
    // MockTermsProcessor public nonCommercialTermsProcessor;
    // MockTermsProcessor public commercialTermsProcessor;
    ICollectModule public collectModule;
    RelationshipModuleHarness public relationshipModuleHarness;
    IPAssetRegistry public registry;

    address public defaultCollectNftImpl;
    address public collectModuleImpl;
    address public accessControlSingletonImpl;

    bool public deployProcessors = false;

    address constant admin = address(123);
    address constant upgrader = address(6969);
    address constant ipAssetOrgOwner = address(456);
    address constant revoker = address(789);
    // string constant NON_COMMERCIAL_LICENSE_URI = "https://noncommercial.license";
    // string constant COMMERCIAL_LICENSE_URI = "https://commercial.license";

    constructor() {}

    function setUp() virtual override(BaseTestUtils) public {
        super.setUp();

        // Create Access Control
        accessControlSingletonImpl = address(new AccessControlSingleton());
        accessControl = AccessControlSingleton(
            _deployUUPSProxy(
                accessControlSingletonImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), admin
                )
            )
        );
        vm.prank(admin);
        accessControl.grantRole(AccessControl.UPGRADER_ROLE, upgrader);
        
        // Create IPAssetRegistry 
        registry = new IPAssetRegistry();

        // Create IPOrg Factory
        ipAssetOrgFactory = new IPOrgFactory();
        
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

        IPAsset.RegisterIPOrgParams memory ipAssetOrgParams = IPAsset.RegisterIPOrgParams(
            address(registry),
            "IPOrgName",
            "FRN",
            "description",
            "tokenURI"
        );

        vm.startPrank(ipAssetOrgOwner);
        address ipAssets;
        ipAssets = ipAssetOrgFactory.registerIPOrg(ipAssetOrgParams);
        ipAssetOrg = IPOrg(ipAssets);
        // licenseRegistry = ILicenseRegistry(ipAssetOrg.getLicenseRegistry());

        // Configure Licensing for IPOrg
        // nonCommercialTermsProcessor = new MockTermsProcessor();
        // commercialTermsProcessor = new MockTermsProcessor();
        // licensingModule.configureIpOrgLicensing(address(ipAssetOrg), _getLicensingConfig());

        vm.stopPrank();

        // Create Relationship Module
        relationshipModuleHarness = new RelationshipModuleHarness(address(ipAssetOrgFactory));
        relationshipModule = RelationshipModuleBase(
            _deployUUPSProxy(
                address(relationshipModuleHarness),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );

        if (deployProcessors) {
            relationshipProcessor = new PermissionlessRelationshipProcessor(address(relationshipModule));
            dstOwnerRelationshipProcessor = new DstOwnerRelationshipProcessor(address(relationshipModule));
        }
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

}
