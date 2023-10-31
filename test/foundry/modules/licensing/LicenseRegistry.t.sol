// // SPDX-License-Identifier: BUSDL-1.1
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import 'test/foundry/utils/BaseTest.sol';
// import 'test/foundry/mocks/MockLicensingModule.sol';
// import 'test/foundry/mocks/MockTermsProcessor.sol';
// import 'test/foundry/mocks/RightsManagerHarness.sol';
// import "test/foundry/mocks/MockERC721.sol";
// import "contracts/errors/General.sol";
// import { Errors } from "contracts/lib/Errors.sol";

// contract LicenseRegistryTest is BaseTest {

//     address licenseHolder = address(0x888888);
//     address receiver = address(0x999999);
//     uint256 licenseId;

//     function setUp() virtual override public {
//         deployProcessors = false;
//         super.setUp();
//         vm.prank(licenseHolder);
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
//         (Licensing.TermsProcessorConfig memory terms,) = LibMockIPAssetOrgConfig.getTermsProcessorConfig();
//         vm.prank(licenseHolder);
//         licenseId = ipAssetOrg.createLicense(
//             ipAssetId,
//             parentLicenseId,
//             licenseHolder,
//             NON_COMMERCIAL_LICENSE_URI,
//             revoker,
//             false,
//             false,
//             terms
//         );

//     }

//     function test_setUp() public {
//         assertEq(licenseRegistry.ownerOf(licenseId), licenseHolder);
//         assertEq(licenseRegistry.name(), "Licenses for IPAssetOrgName");
//         assertEq(licenseRegistry.symbol(), "slFRN");
//         assertEq(address(licenseRegistry.getRightsManager()), address(ipAssetOrg));
//         assertEq(licenseRegistry.exists(licenseId), true);
//     }

//     function test_revert_mint_non_rights_manager() public {
//         vm.expectRevert(Errors.Unauthorized.selector);
//         licenseRegistry.mint(licenseHolder, 1);
//     }

//     function test_transfer() public {
//         assertEq(licenseRegistry.ownerOf(licenseId), licenseHolder);
//         vm.prank(licenseHolder);
//         licenseRegistry.transferFrom(licenseHolder, receiver, licenseId);
//         assertEq(licenseRegistry.ownerOf(licenseId), receiver);
//     }

//     function test_revert_transfer_inactive_license() public {
//         vm.prank(revoker);
//         ipAssetOrg.revokeLicense(licenseId);

//         vm.expectRevert(Errors.RightsManager_InactiveLicense.selector);
//         vm.prank(licenseHolder);
//         licenseRegistry.transferFrom(licenseHolder, receiver, licenseId);
//     }

// }
