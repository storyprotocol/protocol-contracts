// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import '../mocks/MockLicensingModule.sol';
import '../mocks/MockTermsProcessor.sol';
import '../mocks/RightsManagerHarness.sol';
import "../mocks/MockERC721.sol";
import "contracts/errors/General.sol";
import { Errors } from "contracts/lib/Errors.sol";

contract LicenseRegistryTest is BaseTest {

    address licenseHolder = address(0x888888);
    address receiver = address(0x999999);
    uint256 licenseId;

    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
        vm.prank(licenseHolder);
        uint256 ipAssetId = ipAssetGroup.createIpAsset(IPAsset.IPAssetType(1), "name", "description", "mediaUrl", licenseHolder, 0, "");
        uint256 parentLicenseId = ipAssetGroup.getLicenseIdByTokenId(ipAssetId, false);
        (Licensing.TermsProcessorConfig memory terms,) = LibMockIPAssetGroupConfig.getTermsProcessorConfig();
        vm.prank(licenseHolder);
        licenseId = ipAssetGroup.createLicense(
            ipAssetId,
            parentLicenseId,
            licenseHolder,
            NON_COMMERCIAL_LICENSE_URI,
            revoker,
            false,
            false,
            terms
        );

    }

    function test_setUp() public {
        assertEq(licenseRegistry.ownerOf(licenseId), licenseHolder);
        assertEq(licenseRegistry.name(), "Licenses for IPAssetGroupName");
        assertEq(licenseRegistry.symbol(), "slFRN");
        assertEq(address(licenseRegistry.getRightsManager()), address(ipAssetGroup));
        assertEq(licenseRegistry.exists(licenseId), true);
    }

    function test_revert_mint_non_rights_manager() public {
        vm.expectRevert(Errors.Unauthorized.selector);
        licenseRegistry.mint(licenseHolder, 1);
    }

    function test_transfer() public {
        assertEq(licenseRegistry.ownerOf(licenseId), licenseHolder);
        vm.prank(licenseHolder);
        licenseRegistry.transferFrom(licenseHolder, receiver, licenseId);
        assertEq(licenseRegistry.ownerOf(licenseId), receiver);
    }

    function test_revert_transfer_inactive_license() public {
        vm.prank(revoker);
        ipAssetGroup.revokeLicense(licenseId);

        vm.expectRevert(Errors.RightsManager_InactiveLicense.selector);
        vm.prank(licenseHolder);
        licenseRegistry.transferFrom(licenseHolder, receiver, licenseId);
    }

}
