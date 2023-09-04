// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import '../mocks/MockLicensingModule.sol';
import '../mocks/MockTermsProcessor.sol';
import '../mocks/RightsManagerHarness.sol';
import "../mocks/MockERC721.sol";
import "contracts/errors/General.sol";

contract RightsManagerIPAssetRightsTest is BaseTest {

    address ipAssetCreator = address(0x999999);
    address licenseHolder = address(0x888888);

    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
    }

    function test_setUp() public {
        assertEq(licenseRegistry.name(), "Licenses for FranchiseName");
        assertEq(licenseRegistry.symbol(), "slFRN");
        assertEq(address(licenseRegistry.RIGHTS_MANAGER()), address(ipAssetRegistry));

        // Default licensing is root non-commercial with sublicense on, no commercial rights
        ILicensingModule.FranchiseConfig memory configResult = licensingModule.getFranchiseConfig(1);
        assertEq(configResult.nonCommercialConfig.canSublicense, true, "nonCommercialConfig.canSublicense");
        assertEq(configResult.nonCommercialConfig.franchiseRootLicenseId, 0, "nonCommercialConfig.franchiseRootLicenseId");
        assertEq(address(configResult.nonCommercialTerms.processor), address(nonCommercialTermsProcessor), "nonCommercialTerms.processor");
        assertEq(configResult.nonCommercialTerms.data, abi.encode("nonCommercial"), "nonCommercialTerms.data");
        assertEq(configResult.commercialConfig.canSublicense, false, "commercialConfig.canSublicense");
        assertEq(configResult.commercialConfig.franchiseRootLicenseId, 0, "commercialConfig.franchiseRootLicenseId");
        assertEq(address(configResult.commercialTerms.processor), address(commercialTermsProcessor), "commercialTerms.processor");
        assertEq(configResult.commercialTerms.data, abi.encode("commercial"), "commercialTerms.data");
        assertEq(configResult.rootIpAssetHasCommercialRights, false, "rootIpAssetHasCommercialRights");
        assertEq(configResult.revoker, revoker, "revoker");
        
    }

    function test_create_ip_asset_root_noncommercial() public {
        uint256 ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaUrl", ipAssetCreator, 0);
        bool commercial = false;
        uint256 licenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, commercial);
        assertEq(licenseId, 1);
        assertEq(ipAssetRegistry.getLicenseTokenId(licenseId), ipAssetId);
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(licenseId);
        assertEq(owner, ipAssetCreator);
        assertEq(license.active, true);
        assertEq(license.canSublicense, true);
        assertEq(license.commercial, commercial);
        assertEq(license.parentLicenseId, 0);
        assertEq(license.tokenId, ipAssetId);
        assertEq(license.revoker, revoker);
        assertEq(license.uri, "https://noncommercial.license");
        assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
        assertEq(license.termsData, abi.encode("nonCommercial"));

        commercial = true;
        licenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, commercial);
        assertEq(licenseId, 0);
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);
    }

    function test_create_ip_asset_noncommercial_and_commercial() public {
        _configFranchise(true, true, true);
        uint256 ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaUrl", ipAssetCreator, 0);
        bool commercial = false;
        uint256 licenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, commercial);
        assertEq(licenseId, 1);
        assertEq(ipAssetRegistry.getLicenseTokenId(licenseId), ipAssetId);
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(licenseId);
        assertEq(owner, ipAssetCreator);
        assertEq(license.active, true);
        assertEq(license.canSublicense, true);
        assertEq(license.commercial, commercial);
        assertEq(license.parentLicenseId, 0);
        assertEq(license.tokenId, ipAssetId);
        assertEq(license.revoker, revoker);
        assertEq(license.uri, "https://noncommercial.license");
        assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
        assertEq(license.termsData, abi.encode("nonCommercial"));
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);

        commercial = true;
        uint256 commercialLicenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, commercial);
        assertEq(commercialLicenseId, 2);
        assertEq(ipAssetRegistry.getLicenseTokenId(commercialLicenseId), ipAssetId);
        (license, owner) = ipAssetRegistry.getLicense(commercialLicenseId);
        assertEq(owner, ipAssetCreator);
        assertEq(license.active, true);
        assertEq(license.canSublicense, true);
        assertEq(license.commercial, commercial);
        assertEq(license.parentLicenseId, 0);
        assertEq(license.tokenId, ipAssetId);
        assertEq(license.revoker, revoker);
        assertEq(license.uri, "https://commercial.license");
        assertEq(address(license.termsProcessor), address(commercialTermsProcessor));
        assertEq(license.termsData, abi.encode("commercial"));

        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(commercialLicenseId);

    }

    function test_create_derivative_ip_asset_from_non_commercial() public {
        uint256 rootIpAsset = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaUrl", ipAssetCreator, 0);
        uint256 ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name derv", "description deriv", "mediaUrl deriv", ipAssetCreator, rootIpAsset);
        
        bool commercial = false;
        uint256 licenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, commercial);
        
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);
        assertEq(licenseId, 2);
        assertEq(ipAssetRegistry.getLicenseTokenId(licenseId), ipAssetId);
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(licenseId);
        assertEq(owner, ipAssetCreator);
        assertEq(license.active, true);
        assertEq(license.canSublicense, true);
        assertEq(license.commercial, commercial);
        assertEq(license.parentLicenseId, 1);
        assertEq(license.tokenId, ipAssetId);
        assertEq(license.revoker, revoker);
        assertEq(license.uri, "https://noncommercial.license");
        assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
        assertEq(license.termsData, abi.encode("nonCommercial"));

        commercial = true;
        licenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, commercial);
        assertEq(licenseId, 0);
    }

    function test_create_derivative_ip_asset_from_commercial() public {
        _configFranchise(true, true, true);
        uint256 rootIpAsset = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaUrl", ipAssetCreator, 0);
        uint256 ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name derv", "description deriv", "mediaUrl deriv", ipAssetCreator, rootIpAsset);
        
        bool commercial = false;
        uint256 licenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, commercial);
        
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);

        assertEq(licenseId, 3);
        assertEq(ipAssetRegistry.getLicenseTokenId(licenseId), ipAssetId);
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(licenseId);
        assertEq(owner, ipAssetCreator);
        assertEq(license.active, true);
        assertEq(license.canSublicense, true);
        assertEq(license.commercial, commercial);
        assertEq(license.parentLicenseId, 1);
        assertEq(license.tokenId, ipAssetId);
        assertEq(license.revoker, revoker);
        assertEq(license.uri, "https://noncommercial.license");
        assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
        assertEq(license.termsData, abi.encode("nonCommercial"));

        commercial = true;
        licenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, commercial);
        assertEq(licenseId, 0);

    }

    function test_create_license() public {
        uint256 ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaUrl", licenseHolder, 0);
        uint256 parentLicenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, false);
        bool commercial = false;
        vm.prank(licenseHolder);
        uint256 licenseId = ipAssetRegistry.createLicense(
            ipAssetId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            false,
            IERC5218.TermsProcessorConfig({
                processor: nonCommercialTermsProcessor,
                data: abi.encode("terms")
            })
        );
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(licenseId);
        assertEq(owner, licenseHolder);
        assertEq(license.active, true);
        assertEq(license.canSublicense, false);
        assertEq(license.commercial, commercial);
        assertEq(license.parentLicenseId, parentLicenseId);
        assertEq(license.tokenId, ipAssetId);
        assertEq(license.revoker, revoker);
        assertEq(license.uri, "licenseUri");
        assertEq(address(license.termsProcessor), address(nonCommercialTermsProcessor));
        assertEq(license.termsData, abi.encode("terms"));
        assertEq(licenseRegistry.ownerOf(licenseId), licenseHolder);
        
    }

    function test_revert_create_license_unauthorized() public {
        uint256 ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaUrl", ipAssetCreator, 0);
        uint256 parentLicenseId = 1;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        vm.expectRevert(Unauthorized.selector);
        ipAssetRegistry.createLicense(
            ipAssetId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            false,
            terms
        );
    }

    function test_revert_create_license_franchise_owned_tokenId() public {
        uint256 tokenId = ipAssetRegistry.FRANCHISE_REGISTRY_OWNED_TOKEN_ID();
        uint256 parentLicenseId = 1;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        vm.startPrank(franchiseOwner);
        vm.expectRevert(RightsManager.UseCreateFranchiseRootLicenseInstead.selector);
        ipAssetRegistry.createLicense(
            tokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            false,
            terms
        );
        vm.stopPrank();
    }

    function test_revert_create_license_unset_parent() public {
        uint256 tokenId = 1;
        uint256 parentLicenseId = 0;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        vm.startPrank(franchiseOwner);
        vm.expectRevert(RightsManager.UseCreateFranchiseRootLicenseInstead.selector);
        ipAssetRegistry.createLicense(
            tokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            false,
            terms
        );
        vm.stopPrank();
    }

    function test_revert_create_license_terms_mismatch() public {
        uint256 ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaUrl", ipAssetCreator, 0);
        uint256 parentLicenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, false);
        bool commercial = true;
        vm.expectRevert(RightsManager.CommercialTermsMismatch.selector);
        vm.prank(ipAssetCreator);
        ipAssetRegistry.createLicense(
            ipAssetId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            commercial,
            false,
            IERC5218.TermsProcessorConfig({
                processor: nonCommercialTermsProcessor,
                data: abi.encode("terms")
            })
        );
    }

    // This one we can just call the internal method
    function test_create_root_license() public {
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        vm.prank(franchiseOwner);
        uint256 licenseId = ipAssetRegistry.createFranchiseRootLicense(
            1,
            franchiseOwner,
            "licenseUri",
            revoker,
            true,
            true,
            terms
        );
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(licenseId);
        assertEq(owner, franchiseOwner);
        assertEq(license.active, true);
        assertEq(license.canSublicense, true);
        assertEq(license.commercial, true);
        assertEq(license.parentLicenseId, 0);
        assertEq(license.tokenId, ipAssetRegistry.FRANCHISE_REGISTRY_OWNED_TOKEN_ID());
        assertEq(license.revoker, revoker);
        assertEq(license.uri, "licenseUri");
        assertEq(address(license.termsProcessor), address(terms.processor));
        assertEq(license.termsData, abi.encode("terms"));
    }

    function test_revert_create_root_license_unauthorized() public {
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        vm.expectRevert(Unauthorized.selector);
        ipAssetRegistry.createFranchiseRootLicense(
            1,
            franchiseOwner,
            "licenseUri",
            revoker,
            true,
            true,
            terms
        );
    }

    function _verifyLicense(uint256 tokenId, MockTermsProcessor termsProcessor) private returns(uint256) {
        uint256 licenseId = ipAssetRegistry.getLicenseIdByTokenId(tokenId, true);
        assertEq(licenseId, 1);
        assertEq(ipAssetRegistry.getLicenseTokenId(licenseId), tokenId);
        assertEq(ipAssetRegistry.getParentLicenseId(licenseId), 0);
        assertTrue(ipAssetRegistry.isLicenseActive(licenseId));
        assertEq(ipAssetRegistry.getLicenseURI(licenseId), "licenseUri");
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(licenseId);
        assertEq(owner, licenseHolder, "internal method will not create ipasset, but we mockMinted in RightsManagerHarness");
        assertEq(license.active, true, "license active");
        assertEq(license.canSublicense, true, "license canSublicense");
        assertEq(license.commercial, true, "license commercial");
        assertEq(license.parentLicenseId, 0, "license parentLicenseId");
        assertEq(license.tokenId, tokenId, "license tokenId");
        assertEq(license.revoker, revoker, "license revoker");
        assertEq(license.uri, "licenseUri", "license uri");
        assertEq(address(license.termsProcessor), address(termsProcessor), "license termsProcessor");
        assertEq(license.termsData, abi.encode("terms"), "license termsData");
        return licenseId;
    }

    function _configFranchise(bool sublicenseCommercial, bool sublicenseNonCommercial, bool rootIpAssetHasCommercialRights) private {
        ILicensingModule.FranchiseConfig memory config = ILicensingModule.FranchiseConfig({
            nonCommercialConfig: ILicensingModule.IpAssetConfig({
                canSublicense: sublicenseNonCommercial,
                franchiseRootLicenseId: 0
            }),
            nonCommercialTerms: IERC5218.TermsProcessorConfig({
                processor: nonCommercialTermsProcessor,
                data: abi.encode("nonCommercial")
            }),
            commercialConfig: ILicensingModule.IpAssetConfig({
                canSublicense: sublicenseCommercial,
                franchiseRootLicenseId: 0
            }),
            commercialTerms: IERC5218.TermsProcessorConfig({
                processor: commercialTermsProcessor,
                data: abi.encode("commercial")
            }),
            rootIpAssetHasCommercialRights: rootIpAssetHasCommercialRights,
            revoker: revoker,
            commercialLicenseUri: "https://commercial.license"
        });
        vm.prank(franchiseOwner);
        licensingModule.configureFranchiseLicensing(1, config);
    }

}
