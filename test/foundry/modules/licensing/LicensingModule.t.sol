// // SPDX-License-Identifier: BUSDL-1.1
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import 'test/foundry/utils/BaseTest.sol';
// import 'test/foundry/mocks/MockLicensingModule.sol';
// import 'test/foundr/mocks/MockTermsProcessor.sol';
// import { Errors } from "contracts/lib/Errors.sol";
// import { Licensing } from "contracts/lib/modules/Licensing.sol";

// contract LicensingModuleTest is BaseTest {

//     function setUp() virtual override public {
//         deployProcessors = false;
//         super.setUp();
//     }

//     function test_setUp() public {
//         assertEq(licensingModule.getNonCommercialLicenseURI(), NON_COMMERCIAL_LICENSE_URI);
//     }

//     function test_configIPAssetOrg() public {
//         vm.startPrank(ipAssetOrgOwner);
//         Licensing.TermsProcessorConfig memory termsConfig = Licensing.TermsProcessorConfig({
//             processor: commercialTermsProcessor,
//             data: abi.encode("root")
//         });

//         uint256 rootLicenseId = ipAssetOrg.createIPAssetOrgRootLicense(ipAssetOrgOwner, "commercial_uri_root", revoker, true, true, termsConfig);
//         assertEq(licenseRegistry.ownerOf(rootLicenseId), ipAssetOrgOwner);
//         assertEq(rootLicenseId, 1);

//         Licensing.IPAssetOrgConfig memory config = _getLicensingConfig();
//         config.revoker = address(0x5656565);
//         config.commercialConfig.ipAssetOrgRootLicenseId = rootLicenseId;
//         config.commercialTerms.data = abi.encode("bye");
//         config.nonCommercialTerms.data = abi.encode("hi");
        
//         licensingModule.configureIpAssetOrgLicensing(address(ipAssetOrg), config);
//         Licensing.IPAssetOrgConfig memory configResult = licensingModule.getIpAssetOrgConfig(address(ipAssetOrg));
//         assertEq(configResult.nonCommercialConfig.canSublicense, true);
//         assertEq(configResult.nonCommercialConfig.ipAssetOrgRootLicenseId, 0);
//         assertEq(address(configResult.nonCommercialTerms.processor), address(nonCommercialTermsProcessor));
//         assertEq(configResult.nonCommercialTerms.data, abi.encode("hi"));
//         assertEq(configResult.commercialConfig.canSublicense, false);
//         assertEq(configResult.commercialConfig.ipAssetOrgRootLicenseId, 1);
//         assertEq(address(configResult.commercialTerms.processor), address(commercialTermsProcessor));
//         assertEq(configResult.commercialTerms.data, abi.encode("bye"));
//         assertEq(configResult.rootIpAssetHasCommercialRights, false);
//         assertEq(configResult.revoker, address(0x5656565));
//         vm.stopPrank();
//     }

//     function test_revert_nonAuthorizedConfigSetter() public {
//         vm.expectRevert(Errors.Unauthorized.selector);
//         licensingModule.configureIpAssetOrgLicensing(address(ipAssetOrg), LibMockIPAssetOrgConfig.getMockIPAssetOrgConfig());
//     }

//     function test_revert_nonExistingIPAssetOrg() public {
//         // TODO: Changing licensing module to check if address exists.
//         vm.expectRevert();
//         licensingModule.configureIpAssetOrgLicensing(address(0x6954321), LibMockIPAssetOrgConfig.getMockIPAssetOrgConfig());
//     }

//     function test_revert_zeroRevokerAddress() public {
//         vm.startPrank(ipAssetOrgOwner);
//         Licensing.IPAssetOrgConfig memory config = LibMockIPAssetOrgConfig.getMockIPAssetOrgConfig();
//         config.revoker = address(0);
//         vm.expectRevert(Errors.LicensingModule_ZeroRevokerAddress.selector);
//         licensingModule.configureIpAssetOrgLicensing(address(ipAssetOrg), config);
//         vm.stopPrank();
//     }

//     function test_revert_rootLicenseNotActiveCommercial() public {
        
//         Licensing.TermsProcessorConfig memory termsConfig = Licensing.TermsProcessorConfig({
//             processor: commercialTermsProcessor,
//             data: abi.encode("root")
//         });

//         vm.prank(ipAssetOrgOwner);
//         uint256 rootLicenseId = ipAssetOrg.createIPAssetOrgRootLicense(ipAssetOrgOwner, "commercial_uri_root", revoker, true, true, termsConfig);
        
//         commercialTermsProcessor.setSuccess(false);
        
//         Licensing.IPAssetOrgConfig memory config = _getLicensingConfig();
//         config.commercialConfig.ipAssetOrgRootLicenseId = rootLicenseId;
//         vm.startPrank(ipAssetOrgOwner);
//         vm.expectRevert(abi.encodeWithSignature("LicensingModule_RootLicenseNotActive(uint256)", 1));
//         licensingModule.configureIpAssetOrgLicensing(address(ipAssetOrg), config);
//         vm.stopPrank();
        
//     }

// }
