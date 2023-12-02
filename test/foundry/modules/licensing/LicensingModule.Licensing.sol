// // SPDX-License-Identifier: BUSDL-1.1
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import "test/foundry/utils/BaseTest.sol";
// import "contracts/modules/relationships/RelationshipModule.sol";
// import "contracts/lib/modules/LibRelationship.sol";
// import { AccessControl } from "contracts/lib/AccessControl.sol";
// import { Licensing } from "contracts/lib/modules/Licensing.sol";
// import { TermCategories, TermIds } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
// import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
// import { IPAsset } from "contracts/lib/IPAsset.sol";
// import { BaseLicensingTest, LicTestConfig } from "./BaseLicensingTest.sol";

// contract LicensingModuleLicensingTest is BaseLicensingTest {
//     using ShortStrings for *;

//     address lnftOwner = address(0x13334);
//     address ipaOwner2 = address(0x13336);

//     uint256 rootIpaId;

//     function setUp() public override {
//         super.setUp();
//         (rootIpaId, ) = _createIpAsset(ipaOwner, 1, bytes(""));
//     }

//     function test_LicensingModule_createNonCommercialIpaBoundLicense_licensorIpOrg()
//         public
//         withNonCommFramework(LicTestConfig({
//             shareAlike: true,
//             licConfig: TermsData.LicensorConfig.IpOrg,
//             needsActivation: false
//         }))
//     {
//         vm.prank(ipOrg.owner());
//         uint256 lId = spg.createIpaBoundLicense(
//             address(ipOrg),
//             Licensing.LicenseCreation({
//                 parentLicenseId: 0,
//                 isCommercial: false
//             }),
//             rootIpaId,
//             new bytes[](0),
//             new bytes[](0)
//         );
//         Licensing.License memory license = licenseRegistry.getLicense(lId);
//         assertFalse(license.isCommercial, "commercial");
//         assertEq(license.revoker, ipOrg.owner(), "revoker is iporg");
//         assertEq(license.licensor, ipOrg.owner(), "licensor is owner is iporg");
//         assertEq(licenseRegistry.isLicenseActive(lId), true, "license is active");
//         assertEq(licenseRegistry.getLicensee(lId), ipaOwner, "licensee is ipa owner");
//         assertTerms(license);
//         assertEq(license.ipaId, rootIpaId);
//     }

//     function test_LicensingModule_createCommercialLicense_licensorPrevious()
//         public
//         withCommFramework(LicTestConfig({
//             shareAlike: true,
//             licConfig: TermsData.LicensorConfig.ParentLicensee,
//             needsActivation: false
//         }))
//     {
//         vm.prank(ipOrg.owner());
//         uint256 lId = spg.createIpaBoundLicense(
//             address(ipOrg),
//             Licensing.LicenseCreation({
//                 parentLicenseId: 0,
//                 isCommercial: true
//             }),
//             rootIpaId,
//             new bytes[](0),
//             new bytes[](0)
//         );
//         Licensing.License memory license = licenseRegistry.getLicense(lId);
//         assertTrue(license.isCommercial, "is commercial");
//         assertEq(license.licensor,  ipaOwner, "licensor is ipaOwner");

//         uint256 lId2 = spg.createLicenseNft(
//             address(ipOrg),
//             Licensing.LicenseCreation({
//                 parentLicenseId: lId,
//                 isCommercial: true
//             }),
//             lnftOwner,
//             new bytes[](0),
//             new bytes[](0)
//         );
//         Licensing.License memory license2 = licenseRegistry.getLicense(lId2);
//         assertEq(license2.licensor,  licenseRegistry.getLicensee(lId), "licensor is parent licensee");
//         assertEq(license2.parentLicenseId, lId, "parent is first license");
//         assertEq(license2.ipaId, 0, "no ipa id");
//         assertEq(licenseRegistry.getLicensee(lId2), lnftOwner, "licensee is lnft owner");

//     }


//     function test_LicensingModule_terms_revert_shareAlikeOff_LicensorApproval_ActivateAndBound()
//         public
//         withNonCommFramework(LicTestConfig({
//             shareAlike: false,
//             licConfig: TermsData.LicensorConfig.ParentLicensee,
//             needsActivation: true
//         }))
//     {
        
//         // First derivative should work
//         console2.log("First derivative should work");
//         vm.startPrank(ipaOwner);
//         uint256 lid1 = spg.createIpaBoundLicense(
//             address(ipOrg),
//             Licensing.LicenseCreation({
//                 parentLicenseId: 0,
//                 isCommercial: false
//             }),
//             1,
//             new bytes[](0),
//             new bytes[](0)
//         );
//         assertEq(lid1, 1);
//         assertEq(licenseRegistry.isLicenseActive(lid1), false);
//         spg.activateLicense(address(ipOrg), lid1);
//         assertEq(licenseRegistry.isLicenseActive(lid1), true);
//         vm.stopPrank();

//         // Second derivative should fail
//         console2.log("Second derivative should fail");
//         vm.startPrank(ipaOwner2);
//         vm.expectRevert(Errors.LicensingModule_ShareAlikeDisabled.selector);
//         uint256 lid2 = spg.createIpaBoundLicense(
//             address(ipOrg),
//             Licensing.LicenseCreation({
//                 parentLicenseId: lid1,
//                 isCommercial: false
//             }),
//             1,
//             new bytes[](0),
//             new bytes[](0)
//         );
//         vm.stopPrank();

//         // But original ipa owner can emit a license 
//         console2.log("But original ipa owner can emit a license");
//         vm.prank(ipaOwner);
//         lid2 = spg.createLicenseNft(
//             address(ipOrg),
//             Licensing.LicenseCreation({
//                 parentLicenseId: lid1,
//                 isCommercial: false
//             }),
//             ipaOwner,
//             new bytes[](0),
//             new bytes[](0)
//         );
//         // License is not active
//         console2.log("License is not active");
//         Licensing.License memory license2 = licenseRegistry.getLicense(lid2);
//         assertEq(uint8(license2.status), uint8(Licensing.LicenseStatus.Pending));
//         assertFalse(licenseRegistry.isLicenseActive(lid2));
//         assertEq(licenseRegistry.ownerOf(lid2), ipaOwner);
//         assertEq(licenseRegistry.getLicensee(lid2), ipaOwner);
//         assertEq(uint8(license2.licenseeType), uint8(Licensing.LicenseeType.LNFTHolder));

//         // transfer license to other guy
//         console2.log("transfer license to other guy");
//         vm.prank(ipaOwner);
//         licenseRegistry.transferFrom(ipaOwner, ipaOwner2, lid2);
//         assertEq(licenseRegistry.ownerOf(lid2), ipaOwner2);
//         assertEq(licenseRegistry.getLicensee(lid2), ipaOwner2);
//         // Fail to bound if not active
//         console2.log("Fail to bound if not active");
//         vm.expectRevert();
//         spg.linkLnftToIpa(
//             address(ipOrg),
//             lid2,
//             1
//         );
//         // have other guy activate license
//         console2.log("licensee fails to activate license");
//         vm.expectRevert(Errors.LicensingModule_CallerNotLicensor.selector);
//         vm.prank(ipaOwner2);
//         spg.activateLicense(address(ipOrg), lid2);

//         // Licensor must activate
//         console2.log("Licensor must activate");
//         vm.prank(ipaOwner);
//         spg.activateLicense(address(ipOrg), lid2);

//         license2 = licenseRegistry.getLicense(lid2);
//         assertEq(uint8(license2.status), uint8(Licensing.LicenseStatus.Active));
//         assertTrue(licenseRegistry.isLicenseActive(lid2));
        
//         // Link if active
//         console2.log("Link if active");
//         vm.prank(ipaOwner2);
//         spg.linkLnftToIpa(
//             address(ipOrg),
//             lid2,
//             1
//         );
//         license2 = licenseRegistry.getLicense(lid2);
//         assertEq(uint8(license2.licenseeType), uint8(Licensing.LicenseeType.BoundToIpa));
//         vm.expectRevert("ERC721: invalid token ID");
//         assertEq(licenseRegistry.ownerOf(lid2), address(0));
//         // This looks weird because:
//         // IpOwner2 is owner of the lnft
//         // Bounds to ipa1, owned by ipaOwner
//         // Licenseee type is bound to ipa
//         // So ipaOwner is the licensee
//         // In a normal case, ipaOwner2 would bound to an ipa he owns
//         assertEq(licenseRegistry.getLicensee(lid2), ipaOwner);
//     }
    

// }
