// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import '../mocks/MockLicensingModule.sol';
import '../mocks/MockTermsProcessor.sol';
import "contracts/errors/General.sol";

contract RightsManagerIPAssetRightsTest is BaseTest {

    address ipAssetCreator = address(0x999999);

    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
    }

    function test_setUp() public {
        assertEq(licenseRegistry.name(), "Licenses for FranchiseName");
        assertEq(licenseRegistry.symbol(), "slFRN");
        assertEq(address(licenseRegistry.RIGHTS_MANAGER()), address(ipAssetRegistry));
    }

    function test_Rights_NoCommercialRights_RootIPAsset() public {
        
        // TODO: test for events
        vm.prank(ipAssetCreator);
        uint256 ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaurl", address(ipAssetCreator), 0);
        uint256 ncrLicenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, false);
        assertEq(ncrLicenseId, 1);
        assertEq(ipAssetRegistry.getLicenseTokenId(ncrLicenseId), ipAssetId);
        assertEq(ipAssetRegistry.getParentLicenseId(ncrLicenseId), 0);
        assertTrue(ipAssetRegistry.isLicenseActive(ncrLicenseId));
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(ncrLicenseId);
        assertEq(address(ipAssetCreator), owner, "license owner");
        assertEq(license.active, true, "license active");
        assertEq(license.canSublicense, true, "license canSublicense");
        assertEq(license.commercial, false, "license commercial");
        assertEq(license.parentLicenseId, 0, "license parentLicenseId");
        assertEq(license.tokenId, ipAssetId, "license tokenId");
        assertEq(license.revoker, revoker, "license revoker");
        assertEq(license.uri, NON_COMMERCIAL_LICENSE_URI, "license uri");
        assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor), "license termsProcessor");
        assertEq(license.termsData, abi.encode("nonCommercial"), "license termsData");
        uint256 crLicenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, true);
        assertEq(crLicenseId, 0);
        (RightsManager.License memory licenseCr, address ownerCr) = ipAssetRegistry.getLicense(ncrLicenseId);
        assertEq(address(0), ownerCr, "commercial license owner");
    }
    /*
    function test_Rights_CommercialRights_RootIPAsset() public {
        assertTrue(false);
    }
    function test_Rights_CommercialRights_NonRootIPAsset() public {
        assertTrue(false);
    }
    function test_revert_licensingModuleNotConfigured() public {
        assertTrue(false);
    }*/



}
