// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import 'test/foundry/utils/ProxyHelper.sol';
import 'test/foundry/utils/BaseTestUtils.sol';
import "test/foundry/mocks/RelationshipModuleHarness.sol";
import "test/foundry/mocks/MockCollectNFT.sol";
import "test/foundry/mocks/MockCollectModule.sol";
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/access-control/ProtocolRoles.sol";
import "contracts/ip-assets/IPAssetRegistryFactory.sol";
import "contracts/ip-assets/events/CommonIPAssetEventEmitter.sol";
import "contracts/ip-assets/IPAssetRegistry.sol";
import "contracts/IPAsset.sol";
import "contracts/errors/General.sol";
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
import "contracts/modules/relationships/RelationshipModuleBase.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/modules/licensing/LicensingModule.sol";
import "contracts/modules/licensing/terms/ITermsProcessor.sol";
import "contracts/modules/licensing/LicenseRegistry.sol";
import "contracts/interfaces/ICollectModule.sol";

import '../mocks/MockTermsProcessor.sol';

contract BaseTest is BaseTestUtils, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    uint256 public franchiseId;
    address ipAssetRegistryImpl;
    FranchiseRegistry public franchiseRegistry;
    RelationshipModuleBase public relationshipModule;
    AccessControlSingleton accessControl;
    PermissionlessRelationshipProcessor public relationshipProcessor;
    LicensingModule public licensingModule;
    ILicenseRegistry public licenseRegistry;
    MockTermsProcessor public nonCommercialTermsProcessor;
    MockTermsProcessor public commercialTermsProcessor;
    ICollectModule public collectModule;
    RelationshipModuleHarness public relationshipModuleHarness;
    address eventEmitter;
    address public franchiseRegistryImpl;
    address public defaultCollectNFTImpl;
    address public collectModuleImpl;
    address public accessControlSingletonImpl;

    bool public deployProcessors = false;

    address constant admin = address(123);
    address constant franchiseOwner = address(456);
    address constant revoker = address(789);
    string constant NON_COMMERCIAL_LICENSE_URI = "https://noncommercial.license";
    string constant COMMERCIAL_LICENSE_URI = "https://commercial.license";

    constructor() {}

    function setUp() virtual override(BaseTestUtils) public {
        super.setUp();
        factory = new IPAssetRegistryFactory();

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
        
        // Create Franchise Registry
        franchiseRegistryImpl = address(new FranchiseRegistry(address(factory)));
        franchiseRegistry = FranchiseRegistry(
            _deployUUPSProxy(
                franchiseRegistryImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
        // Create Common Event Emitter
        eventEmitter = address(new CommonIPAssetEventEmitter(address(franchiseRegistry)));
        
        // Create Licensing Module
        address licensingImplementation = address(new LicensingModule(address(franchiseRegistry)));
        licensingModule = LicensingModule(
            _deployUUPSProxy(
                licensingImplementation,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address,string)"))),
                    address(accessControl), NON_COMMERCIAL_LICENSE_URI
                )
            )
        );

        
        // upgrade factory to use new event emitter
        ipAssetRegistryImpl = address(new IPAssetRegistry(eventEmitter, address(licensingModule), address(franchiseRegistry)));
        factory.upgradeFranchises(ipAssetRegistryImpl);
        
        vm.startPrank(franchiseOwner);

        // Register Franchise (will create IPAssetRegistry and associated LicenseRegistry)
        FranchiseRegistry.FranchiseCreationParams memory params = FranchiseRegistry.FranchiseCreationParams("FranchiseName", "FRN", "description", "tokenURI");
        address ipAssets;
        (franchiseId, ipAssets) = franchiseRegistry.registerFranchise(params);
        ipAssetRegistry = IPAssetRegistry(ipAssets);
        licenseRegistry = ILicenseRegistry(ipAssetRegistry.getLicenseRegistry());

        // Configure Licensing for Franchise
        nonCommercialTermsProcessor = new MockTermsProcessor();
        commercialTermsProcessor = new MockTermsProcessor();
        licensingModule.configureFranchiseLicensing(franchiseId, _getLicensingConfig());

        vm.stopPrank();

        // Create Relationship Module
        relationshipModuleHarness = new RelationshipModuleHarness(address(franchiseRegistry));
        relationshipModule = RelationshipModuleBase(
            _deployUUPSProxy(
                address(relationshipModuleHarness),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );

        // Deploy collect module and collect NFT impl
        defaultCollectNFTImpl = address(new MockCollectNFT());
        collectModuleImpl = address(new MockCollectModule(address(franchiseRegistry), defaultCollectNFTImpl));

        collectModule = ICollectModule(
            _deployUUPSProxy(
                collectModuleImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
        if (deployProcessors) {
            relationshipProcessor = new PermissionlessRelationshipProcessor(address(relationshipModule));
        }
    }

    function _getLicensingConfig() view internal returns (ILicensingModule.FranchiseConfig memory) {
        return ILicensingModule.FranchiseConfig({
            nonCommercialConfig: ILicensingModule.IpAssetConfig({
                canSublicense: true,
                franchiseRootLicenseId: 0
            }),
            nonCommercialTerms: IERC5218.TermsProcessorConfig({
                processor: nonCommercialTermsProcessor,
                data: abi.encode("nonCommercial")
            }),
            commercialConfig: ILicensingModule.IpAssetConfig({
                canSublicense: false,
                franchiseRootLicenseId: 0
            }),
            commercialTerms: IERC5218.TermsProcessorConfig({
                processor: commercialTermsProcessor,
                data: abi.encode("commercial")
            }),
            rootIpAssetHasCommercialRights: false,
            revoker: revoker,
            commercialLicenseUri: "uriuri"
        });
    }


    /// @dev Helper function for creating an IP asset for an owner and IP type.
    ///      TO-DO: Replace this with a simpler set of default owners that get
    ///      tested against. The reason this is currently added is that during
    ///      fuzz testing, foundry may plug existing contracts as potential
    ///      owners for IP asset creation.
    function _createIPAsset(address ipAssetOwner, uint8 ipAssetType) internal isValidReceiver(ipAssetOwner) returns (uint256) {
        vm.assume(ipAssetType > uint8(type(IPAsset).min));
        vm.assume(ipAssetType < uint8(type(IPAsset).max));
        vm.assume(ipAssetOwner != address(0));
        vm.assume(ipAssetOwner != address(franchiseRegistry));
        vm.assume(ipAssetOwner != address(factory));
        vm.assume(ipAssetOwner != address(relationshipModule));
        vm.assume(ipAssetOwner != address(accessControl));
        vm.assume(ipAssetOwner != address(accessControlSingletonImpl));
        vm.assume(ipAssetOwner != address(collectModule));
        vm.assume(ipAssetOwner != address(collectModuleImpl));
        vm.assume(ipAssetOwner != address(defaultCollectNFTImpl));
        vm.assume(ipAssetOwner != address(franchiseRegistryImpl));
        vm.assume(ipAssetOwner != address(relationshipProcessor));
        vm.assume(ipAssetOwner != address(ipAssetRegistry));
        vm.assume(ipAssetOwner != address(relationshipModuleHarness));
        vm.assume(ipAssetOwner != address(ipAssetRegistryImpl));
        vm.assume(ipAssetOwner != address(eventEmitter));
        vm.prank(ipAssetOwner);
        return ipAssetRegistry.createIPAsset(IPAsset(ipAssetType), "name", "description", "mediaUrl", ipAssetOwner, 0);
    }
}
