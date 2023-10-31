// // SPDX-License-Identifier: BUSDL-1.1
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import 'test/foundry/utils/BaseTest.sol';
// import 'test/foundry/mocks/MockLicensingModule.sol';
// import 'test/foundry/mocks/MockTermsProcessor.sol';
// import 'test/foundry/mocks/RightsManagerHarness.sol';
// import "test/foundry/mocks/MockERC721.sol";
// import { Errors } from "contracts/lib/Errors.sol";
// import { Licensing } from "contracts/lib/modules/Licensing.sol";

// contract RightsManagerIPAssetRightsTest is BaseTest {

//     address ipAssetCreator = address(0x999999);
//     address licenseHolder = address(0x888888);

//     function setUp() virtual override public {
//         deployProcessors = false;
//         super.setUp();
//     }

//     function test_setUp() public {
//         assertEq(licenseRegistry.name(), "Licenses for IPAssetOrgName");
//         assertEq(licenseRegistry.symbol(), "slFRN");
//         assertEq(address(licenseRegistry.getRightsManager()), address(ipAssetOrg));

//         // Default licensing is root non-commercial with sublicense on, no commercial rights
//         Licensing.IPAssetOrgConfig memory configResult = licensingModule.getIpAssetOrgConfig(address(ipAssetOrg));
//         assertEq(configResult.nonCommercialConfig.canSublicense, true, "nonCommercialConfig.canSublicense");
//         assertEq(configResult.nonCommercialConfig.ipAssetOrgRootLicenseId, 0, "nonCommercialConfig.ipAssetOrgRootLicenseId");
//         assertEq(address(configResult.nonCommercialTerms.processor), address(nonCommercialTermsProcessor), "nonCommercialTerms.processor");
//         assertEq(configResult.nonCommercialTerms.data, abi.encode("nonCommercial"), "nonCommercialTerms.data");
//         assertEq(configResult.commercialConfig.canSublicense, false, "commercialConfig.canSublicense");
//         assertEq(configResult.commercialConfig.ipAssetOrgRootLicenseId, 0, "commercialConfig.ipAssetOrgRootLicenseId");
//         assertEq(address(configResult.commercialTerms.processor), address(commercialTermsProcessor), "commercialTerms.processor");
//         assertEq(configResult.commercialTerms.data, abi.encode("commercial"), "commercialTerms.data");
//         assertEq(configResult.rootIpAssetHasCommercialRights, false, "rootIpAssetHasCommercialRights");
//         assertEq(configResult.revoker, revoker, "revoker");
        
//     }

//     function test_create_ip_asset_root_noncommercial() public {
//         (, uint256 ipAssetId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType(1),
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetCreator,
//             parentIpAssetOrgId: 0,
//             collectData: ""
//         }));
//         bool commercial = false;
//         uint256 licenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, commercial);
//         assertEq(licenseId, 1);
//         assertEq(ipAssetOrg.getLicenseTokenId(licenseId), ipAssetId);
//         (Licensing.License memory license, address owner) = ipAssetOrg.getLicense(licenseId);
//         assertEq(owner, ipAssetCreator);
//         assertEq(license.active, true);
//         assertEq(license.canSublicense, true);
//         assertEq(license.commercial, commercial);
//         assertEq(license.parentLicenseId, 0);
//         assertEq(license.tokenId, ipAssetId);
//         assertEq(license.revoker, revoker);
//         assertEq(license.uri, "https://noncommercial.license");
//         assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
//         assertEq(license.termsData, abi.encode("nonCommercial"));

//         commercial = true;
//         licenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, commercial);
//         assertEq(licenseId, 0);
//         vm.expectRevert("ERC721: invalid token ID");
//         licenseRegistry.ownerOf(licenseId);
//     }

//     function test_create_ip_asset_noncommercial_and_commercial() public {
//         _configIPAssetOrg(true, true, true);
//         (, uint256 ipAssetId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType(1),
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetCreator,
//             parentIpAssetOrgId: 0,
//             collectData: ""
//         }));
//         bool commercial = false;
//         uint256 licenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, commercial);
//         assertEq(licenseId, 1);
//         assertEq(ipAssetOrg.getLicenseTokenId(licenseId), ipAssetId);
//         (Licensing.License memory license, address owner) = ipAssetOrg.getLicense(licenseId);
//         assertEq(owner, ipAssetCreator);
//         assertEq(license.active, true);
//         assertEq(license.canSublicense, true);
//         assertEq(license.commercial, commercial);
//         assertEq(license.parentLicenseId, 0);
//         assertEq(license.tokenId, ipAssetId);
//         assertEq(license.revoker, revoker);
//         assertEq(license.uri, "https://noncommercial.license");
//         assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
//         assertEq(license.termsData, abi.encode("nonCommercial"));
//         vm.expectRevert("ERC721: invalid token ID");
//         licenseRegistry.ownerOf(licenseId);

//         commercial = true;
//         uint256 commercialLicenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, commercial);
//         assertEq(commercialLicenseId, 2);
//         assertEq(ipAssetOrg.getLicenseTokenId(commercialLicenseId), ipAssetId);
//         (license, owner) = ipAssetOrg.getLicense(commercialLicenseId);
//         assertEq(owner, ipAssetCreator);
//         assertEq(license.active, true);
//         assertEq(license.canSublicense, true);
//         assertEq(license.commercial, commercial);
//         assertEq(license.parentLicenseId, 0);
//         assertEq(license.tokenId, ipAssetId);
//         assertEq(license.revoker, revoker);
//         assertEq(license.uri, "https://commercial.license");
//         assertEq(address(license.termsProcessor), address(commercialTermsProcessor));
//         assertEq(license.termsData, abi.encode("commercial"));

//         vm.expectRevert("ERC721: invalid token ID");
//         licenseRegistry.ownerOf(commercialLicenseId);

//     }

//     function test_create_derivative_ip_asset_from_non_commercial() public {
//         (, uint256 rootIpAsset) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType(1),
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetCreator,
//             parentIpAssetOrgId: 0,
//             collectData: ""
//         }));
//         (, uint256 ipAssetId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType(1),
//             name: "name derv",
//             description: "description deriv",
//             mediaUrl: "mediaUrl deriv",
//             to: ipAssetCreator,
//             parentIpAssetOrgId: rootIpAsset,
//             collectData: ""
//         }));
        
//         bool commercial = false;
//         uint256 licenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, commercial);
        
//         vm.expectRevert("ERC721: invalid token ID");
//         licenseRegistry.ownerOf(licenseId);
//         assertEq(licenseId, 2);
//         assertEq(ipAssetOrg.getLicenseTokenId(licenseId), ipAssetId);
//         (Licensing.License memory license, address owner) = ipAssetOrg.getLicense(licenseId);
//         assertEq(owner, ipAssetCreator);
//         assertEq(license.active, true);
//         assertEq(license.canSublicense, true);
//         assertEq(license.commercial, commercial);
//         assertEq(license.parentLicenseId, 1);
//         assertEq(license.tokenId, ipAssetId);
//         assertEq(license.revoker, revoker);
//         assertEq(license.uri, "https://noncommercial.license");
//         assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
//         assertEq(license.termsData, abi.encode("nonCommercial"));

//         commercial = true;
//         licenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, commercial);
//         assertEq(licenseId, 0);
//     }

//     function test_create_derivative_ip_asset_from_commercial() public {
//         _configIPAssetOrg(true, true, true);
//         (, uint256 rootIpAsset) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType(1),
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetCreator,
//             parentIpAssetOrgId: 0,
//             collectData: ""
//         }));
//         (, uint256 ipAssetId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType(1),
//             name: "name deriv",
//             description: "description deriv",
//             mediaUrl: "mediaUrl deriv",
//             to: ipAssetCreator,
//             parentIpAssetOrgId: rootIpAsset,
//             collectData: ""
//         }));
        
//         bool commercial = false;
//         uint256 licenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, commercial);
        
//         vm.expectRevert("ERC721: invalid token ID");
//         licenseRegistry.ownerOf(licenseId);

//         assertEq(licenseId, 3);
//         assertEq(ipAssetOrg.getLicenseTokenId(licenseId), ipAssetId);
//         (Licensing.License memory license, address owner) = ipAssetOrg.getLicense(licenseId);
//         assertEq(owner, ipAssetCreator);
//         assertEq(license.active, true);
//         assertEq(license.canSublicense, true);
//         assertEq(license.commercial, commercial);
//         assertEq(license.parentLicenseId, 1);
//         assertEq(license.tokenId, ipAssetId);
//         assertEq(license.revoker, revoker);
//         assertEq(license.uri, "https://noncommercial.license");
//         assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
//         assertEq(license.termsData, abi.encode("nonCommercial"));

//         commercial = true;
//         licenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, commercial);
//         assertEq(licenseId, 0);

//     }

//     function test_create_license() public {
//         (, uint256 ipAssetId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType(1),
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: licenseHolder,
//             parentIpAssetOrgId: 0,
//             collectData: ""
//         }));
//         uint256 parentLicenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, false);
//         bool commercial = false;
//         vm.prank(licenseHolder);
//         uint256 licenseId = ipAssetOrg.createLicense(
//             ipAssetId,
//             parentLicenseId,
//             licenseHolder,
//             "licenseUri",
//             revoker,
//             false,
//             false,
//             Licensing.TermsProcessorConfig({
//                 processor: nonCommercialTermsProcessor,
//                 data: abi.encode("terms")
//             })
//         );
//         (Licensing.License memory license, address owner) = ipAssetOrg.getLicense(licenseId);
//         assertEq(owner, licenseHolder);
//         assertEq(license.active, true);
//         assertEq(license.canSublicense, false);
//         assertEq(license.commercial, commercial);
//         assertEq(license.parentLicenseId, parentLicenseId);
//         assertEq(license.tokenId, ipAssetId);
//         assertEq(license.revoker, revoker);
//         assertEq(license.uri, "licenseUri");
//         assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
//         assertEq(license.termsData, abi.encode("terms"));
//         assertEq(licenseRegistry.ownerOf(licenseId), licenseHolder);
        
//     }

//     function test_revert_create_license_unauthorized() public {
//         (, uint256 ipAssetId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType(1),
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetCreator,
//             parentIpAssetOrgId: 0,
//             collectData: ""
//         }));
//         uint256 parentLicenseId = 1;
//         (Licensing.TermsProcessorConfig memory terms,) = LibMockIPAssetOrgConfig.getTermsProcessorConfig();
//         vm.expectRevert(Errors.Unauthorized.selector);
//         ipAssetOrg.createLicense(
//             ipAssetId,
//             parentLicenseId,
//             licenseHolder,
//             "licenseUri",
//             revoker,
//             false,
//             false,
//             terms
//         );
//     }

//     function test_revert_create_license_franchise_owned_tokenId() public {
//         uint256 tokenId = ipAssetOrg.ROOT_LICENSE_ID();
//         uint256 parentLicenseId = 1;
//         (Licensing.TermsProcessorConfig memory terms,) = LibMockIPAssetOrgConfig.getTermsProcessorConfig();
//         vm.startPrank(ipAssetOrgOwner);
//         vm.expectRevert(Errors.RightsManager_UseCreateIPAssetOrgRootLicenseInstead.selector);
//         ipAssetOrg.createLicense(
//             tokenId,
//             parentLicenseId,
//             licenseHolder,
//             "licenseUri",
//             revoker,
//             false,
//             false,
//             terms
//         );
//         vm.stopPrank();
//     }

//     function test_revert_create_license_unset_parent() public {
//         uint256 tokenId = 1;
//         uint256 parentLicenseId = 0;
//         (Licensing.TermsProcessorConfig memory terms,) = LibMockIPAssetOrgConfig.getTermsProcessorConfig();
//         vm.startPrank(ipAssetOrgOwner);
//         vm.expectRevert(Errors.RightsManager_UseCreateIPAssetOrgRootLicenseInstead.selector);
//         ipAssetOrg.createLicense(
//             tokenId,
//             parentLicenseId,
//             licenseHolder,
//             "licenseUri",
//             revoker,
//             false,
//             false,
//             terms
//         );
//         vm.stopPrank();
//     }

//     function test_revert_create_license_terms_mismatch() public {
//         (, uint256 ipAssetId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType(1),
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetCreator,
//             parentIpAssetOrgId: 0,
//             collectData: ""
//         }));

//         uint256 parentLicenseId = ipAssetOrg.getLicenseIdByTokenId(ipAssetId, false);
//         bool commercial = true;
//         vm.expectRevert(Errors.RightsManager_CommercialTermsMismatch.selector);
//         vm.prank(ipAssetCreator);
//         ipAssetOrg.createLicense(
//             ipAssetId,
//             parentLicenseId,
//             licenseHolder,
//             "licenseUri",
//             revoker,
//             commercial,
//             false,
//             Licensing.TermsProcessorConfig({
//                 processor: nonCommercialTermsProcessor,
//                 data: abi.encode("terms")
//             })
//         );
//     }

//     // This one we can just call the internal method
//     function test_create_root_license() public {
//         (Licensing.TermsProcessorConfig memory terms,) = LibMockIPAssetOrgConfig.getTermsProcessorConfig();
//         vm.prank(ipAssetOrgOwner);
//         uint256 licenseId = ipAssetOrg.createIPAssetOrgRootLicense(
//             ipAssetOrgOwner,
//             "licenseUri",
//             revoker,
//             true,
//             true,
//             terms
//         );
//         (Licensing.License memory license, address owner) = ipAssetOrg.getLicense(licenseId);
//         assertEq(owner, ipAssetOrgOwner);
//         assertEq(license.active, true);
//         assertEq(license.canSublicense, true);
//         assertEq(license.commercial, true);
//         assertEq(license.parentLicenseId, 0);
//         assertEq(license.tokenId, ipAssetOrg.ROOT_LICENSE_ID());
//         assertEq(license.revoker, revoker);
//         assertEq(license.uri, "licenseUri");
//         assertEq(address(license.termsProcessor), address(terms.processor));
//         assertEq(license.termsData, abi.encode("terms"));
//     }

//     function test_revert_create_root_license_unauthorized() public {
//         (Licensing.TermsProcessorConfig memory terms,) = LibMockIPAssetOrgConfig.getTermsProcessorConfig();
//         vm.expectRevert(Errors.Unauthorized.selector);
//         ipAssetOrg.createIPAssetOrgRootLicense(
//             ipAssetOrgOwner,
//             "licenseUri",
//             revoker,
//             true,
//             true,
//             terms
//         );
//     }

//     function _verifyLicense(uint256 tokenId, MockTermsProcessor termsProcessor) private returns(uint256) {
//         uint256 licenseId = ipAssetOrg.getLicenseIdByTokenId(tokenId, true);
//         assertEq(licenseId, 1);
//         assertEq(ipAssetOrg.getLicenseTokenId(licenseId), tokenId);
//         assertEq(ipAssetOrg.getParentLicenseId(licenseId), 0);
//         assertTrue(ipAssetOrg.isLicenseActive(licenseId));
//         assertEq(ipAssetOrg.getLicenseURI(licenseId), "licenseUri");
//         (Licensing.License memory license, address owner) = ipAssetOrg.getLicense(licenseId);
//         assertEq(owner, licenseHolder, "internal method will not create ipasset, but we mockMinted in RightsManagerHarness");
//         assertEq(license.active, true, "license active");
//         assertEq(license.canSublicense, true, "license canSublicense");
//         assertEq(license.commercial, true, "license commercial");
//         assertEq(license.parentLicenseId, 0, "license parentLicenseId");
//         assertEq(license.tokenId, tokenId, "license tokenId");
//         assertEq(license.revoker, revoker, "license revoker");
//         assertEq(license.uri, "licenseUri", "license uri");
//         assertEq(address(license.termsProcessor), address(termsProcessor), "license termsProcessor");
//         assertEq(license.termsData, abi.encode("terms"), "license termsData");
//         return licenseId;
//     }

//     function _configIPAssetOrg(bool sublicenseCommercial, bool sublicenseNonCommercial, bool rootIpAssetHasCommercialRights) private {
//         Licensing.IPAssetOrgConfig memory config = Licensing.IPAssetOrgConfig({
//             nonCommercialConfig: Licensing.IpAssetConfig({
//                 canSublicense: sublicenseNonCommercial,
//                 ipAssetOrgRootLicenseId: 0
//             }),
//             nonCommercialTerms: Licensing.TermsProcessorConfig({
//                 processor: nonCommercialTermsProcessor,
//                 data: abi.encode("nonCommercial")
//             }),
//             commercialConfig: Licensing.IpAssetConfig({
//                 canSublicense: sublicenseCommercial,
//                 ipAssetOrgRootLicenseId: 0
//             }),
//             commercialTerms: Licensing.TermsProcessorConfig({
//                 processor: commercialTermsProcessor,
//                 data: abi.encode("commercial")
//             }),
//             rootIpAssetHasCommercialRights: rootIpAssetHasCommercialRights,
//             revoker: revoker,
//             commercialLicenseUri: "https://commercial.license"
//         });
//         vm.prank(ipAssetOrgOwner);
//         licensingModule.configureIpAssetOrgLicensing(address(ipAssetOrg), config);
//     }

// }
