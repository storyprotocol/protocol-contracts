// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import 'test/foundry/utils/ProxyHelper.sol';
import 'test/foundry/utils/BaseTestUtils.sol';
import "test/foundry/mocks/RelationshipModuleHarness.sol";
import "test/foundry/mocks/MockCollectNFT.sol";
import "test/foundry/mocks/MockCollectModule.sol";
import "contracts/IPAssetOrgFactory.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/ip-assets/IPAssetOrg.sol";
import "contracts/lib/IPAsset.sol";
import "contracts/errors/General.sol";
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
import "contracts/modules/relationships/processors/DstOwnerRelationshipProcessor.sol";
import "contracts/modules/relationships/RelationshipModuleBase.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/modules/licensing/LicensingModule.sol";
import "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
import "contracts/modules/licensing/LicenseRegistry.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/interfaces/modules/collect/ICollectModule.sol";
import '../mocks/MockTermsProcessor.sol';

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";

contract BaseTest is BaseTestUtils, ProxyHelper {

    IPAssetOrg public ipAssetOrg;
    address ipAssetOrgImpl;
    IPAssetOrgFactory public ipAssetOrgFactory;
    RelationshipModuleBase public relationshipModule;
    AccessControlSingleton accessControl;
    PermissionlessRelationshipProcessor public relationshipProcessor;
    DstOwnerRelationshipProcessor public dstOwnerRelationshipProcessor;
    LicensingModule public licensingModule;
    ILicenseRegistry public licenseRegistry;
    MockTermsProcessor public nonCommercialTermsProcessor;
    MockTermsProcessor public commercialTermsProcessor;
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
    string constant NON_COMMERCIAL_LICENSE_URI = "https://noncommercial.license";
    string constant COMMERCIAL_LICENSE_URI = "https://commercial.license";

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

        // Create IPAssetOrg Factory
        ipAssetOrgFactory = new IPAssetOrgFactory();
        
        // Create Licensing Module
        address licensingImplementation = address(new LicensingModule(address(ipAssetOrgFactory)));
        licensingModule = LicensingModule(
            _deployUUPSProxy(
                licensingImplementation,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address,string)"))),
                    address(accessControl), NON_COMMERCIAL_LICENSE_URI
                )
            )
        );

        defaultCollectNftImpl = _deployCollectNFTImpl();
        collectModule = ICollectModule(_deployCollectModule(defaultCollectNftImpl));

        IPAsset.RegisterIPAssetOrgParams memory ipAssetOrgParams = IPAsset.RegisterIPAssetOrgParams(
            address(registry),
            "IPAssetOrgName",
            "FRN",
            "description",
            "tokenURI",
            address(licensingModule),
            address(collectModule)
        );

        vm.startPrank(ipAssetOrgOwner);
        address ipAssets;
        ipAssets = ipAssetOrgFactory.registerIPAssetOrg(ipAssetOrgParams);
        ipAssetOrg = IPAssetOrg(ipAssets);
        licenseRegistry = ILicenseRegistry(ipAssetOrg.getLicenseRegistry());

        // Configure Licensing for IPAssetOrg
        nonCommercialTermsProcessor = new MockTermsProcessor();
        commercialTermsProcessor = new MockTermsProcessor();
        licensingModule.configureIpAssetOrgLicensing(address(ipAssetOrg), _getLicensingConfig());

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

    function _getLicensingConfig() view internal returns (Licensing.IPAssetOrgConfig memory) {
        return Licensing.IPAssetOrgConfig({
            nonCommercialConfig: Licensing.IpAssetConfig({
                canSublicense: true,
                ipAssetOrgRootLicenseId: 0
            }),
            nonCommercialTerms: Licensing.TermsProcessorConfig({
                processor: nonCommercialTermsProcessor,
                data: abi.encode("nonCommercial")
            }),
            commercialConfig: Licensing.IpAssetConfig({
                canSublicense: false,
                ipAssetOrgRootLicenseId: 0
            }),
            commercialTerms: Licensing.TermsProcessorConfig({
                processor: commercialTermsProcessor,
                data: abi.encode("commercial")
            }),
            rootIpAssetHasCommercialRights: false,
            revoker: revoker,
            commercialLicenseUri: "uriuri"
        });
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
        vm.assume(ipAssetType > uint8(type(IPAsset.IPAssetType).min));
        vm.assume(ipAssetType < uint8(type(IPAsset.IPAssetType).max));
        vm.prank(address(ipAssetOrg));
        (uint256 id, ) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
            ipAssetType: IPAsset.IPAssetType(ipAssetType),
            name: "name",
            description: "description",
            mediaUrl: "mediaUrl",
            to: ipAssetOwner,
            parentIpAssetOrgId: 0,
            collectData: collectData
        }));
        return id;
    }

}
