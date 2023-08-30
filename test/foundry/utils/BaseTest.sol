// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import 'test/foundry/utils/ProxyHelper.sol';
import "test/foundry/mocks/RelationshipModuleHarness.sol";
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
import '../mocks/MockTermsProcessor.sol';

contract BaseTest is Test, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    FranchiseRegistry public franchiseRegistry;
    RelationshipModuleBase public relationshipModule;
    AccessControlSingleton accessControl;
    PermissionlessRelationshipProcessor public relationshipProcessor;
    LicensingModule public licensingModule;
    LicenseRegistry public licenseRegistry;
    MockTermsProcessor public nonCommercialTermsProcessor;
    MockTermsProcessor public commercialTermsProcessor;
    bool public deployProcessors = false;

    address constant admin = address(123);
    address constant franchiseOwner = address(456);
    address constant revoker = address(789);
    string constant NON_COMMERCIAL_LICENSE_URI = "https://noncommercial.license";
    string constant COMMERCIAL_LICENSE_URI = "https://commercial.license";

    constructor() {}

    function setUp() virtual public {
        factory = new IPAssetRegistryFactory();

        // Create Access Control
        accessControl = AccessControlSingleton(
            _deployUUPSProxy(
                address(new AccessControlSingleton()),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), admin
                )
            )
        );
        
        // Create Franchise Registry
        FranchiseRegistry impl = new FranchiseRegistry(address(factory));
        franchiseRegistry = FranchiseRegistry(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );

        // Create Common Event Emitter
        address eventEmitter = address(new CommonIPAssetEventEmitter(address(franchiseRegistry)));
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
        factory.upgradeFranchises(address(new IPAssetRegistry(eventEmitter, address(licensingModule), address(franchiseRegistry))));
        vm.startPrank(franchiseOwner);

        // Register Franchise (will create IPAssetRegistry and associated LicenseRegistry)
        FranchiseRegistry.FranchiseCreationParams memory params = FranchiseRegistry.FranchiseCreationParams("FranchiseName", "FRN", "description", "tokenURI");
        (uint256 franchiseId, address ipAssets) = franchiseRegistry.registerFranchise(params);
        ipAssetRegistry = IPAssetRegistry(ipAssets);
        licenseRegistry = ipAssetRegistry.getLicenseRegistry();

        // Configure Licensing for Franchise
        licensingModule.configureFranchiseLicensing(franchiseId, _getLicensingConfig());

        vm.stopPrank();

        // Create Relationship Module
        relationshipModule = RelationshipModuleBase(
            _deployUUPSProxy(
                address(new RelationshipModuleHarness(address(franchiseRegistry))),
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

}