// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import '../mocks/MockLicensingModule.sol';
import '../mocks/MockTermsProcessor.sol';
import '../mocks/RightsManagerHarness.sol';
import "../mocks/MockERC721.sol";
import "contracts/errors/General.sol"; 


contract RightsManagerTest is Test, ProxyHelper {

    MockERC721 mockFranchiseRegistry;
    RightsManagerHarness rightsManager;
    address constant mockEventEmitter = address(0x1234567);
    address constant mockLicensingModule = address(0x23445);
    address constant licenseHolder = address(0x8073465);
    address constant revoker = address(0x123456722222);
    
    function setUp() public {
        mockFranchiseRegistry = new MockERC721("mockFranchiseRegistry", "MFR");
        RightsManagerHarness impl = new RightsManagerHarness(mockEventEmitter, mockLicensingModule, address(mockFranchiseRegistry));
        rightsManager = RightsManagerHarness(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(
                        keccak256(
                            bytes("initialize(uint256,string,string,string)")
                        )
                    ),
                    1,
                    "name",
                    "symbol",
                    "description"
                )
            )
        );

    }

    function test_setup() public {
        assertEq(address(rightsManager.FRANCHISE_REGISTRY()), address(mockFranchiseRegistry));
        assertEq(rightsManager.name(), "name");
        assertEq(rightsManager.symbol(), "symbol");
    }

    function test_internal_create_license_rootLicense_notminting() public {
        uint256 tokenId = 1;
        rightsManager.mint(licenseHolder, tokenId);
        uint256 parentLicenseId = 0;
        MockTermsProcessor termsProcessor = new MockTermsProcessor();
        IERC5218.TermsProcessorConfig memory terms = IERC5218.TermsProcessorConfig({
            processor: termsProcessor,
            data: abi.encode("terms")
        });
        // TODO test events
        rightsManager.createLicense_exposed(
            tokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            true,
            true,
            terms,
            false
        );
        uint256 licenseId = _verifyLicense(tokenId, termsProcessor);
        LicenseRegistry licenseRegistry = LicenseRegistry(rightsManager.getLicenseRegistry());
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);

    }

    function test_internal_create_license_rootLicense_minting() public {
        uint256 tokenId = 1;
        rightsManager.mint(licenseHolder, tokenId);
        uint256 parentLicenseId = 0;
        MockTermsProcessor termsProcessor = new MockTermsProcessor();
        IERC5218.TermsProcessorConfig memory terms = IERC5218.TermsProcessorConfig({
            processor: termsProcessor,
            data: abi.encode("terms")
        });
        // TODO test events
        rightsManager.createLicense_exposed(
            tokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            true,
            true,
            terms,
            true
        );
        uint256 licenseId = _verifyLicense(tokenId, termsProcessor);
        LicenseRegistry licenseRegistry = LicenseRegistry(rightsManager.getLicenseRegistry());
        assertEq(licenseRegistry.ownerOf(licenseId), licenseHolder);
    }

    function test_internal_create_license_nonRootLicense_notminting() public {
        uint256 tokenId = 1;
        rightsManager.mint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        MockTermsProcessor termsProcessor = new MockTermsProcessor();
        IERC5218.TermsProcessorConfig memory terms = IERC5218.TermsProcessorConfig({
            processor: termsProcessor,
            data: abi.encode("terms")
        });
        // Mint root
        rightsManager.createLicense_exposed(
            tokenId,
            0,
            licenseHolder,
            "licenseUri",
            revoker,
            true,
            true,
            terms,
            false
        );
        // Mint sublicense
        rightsManager.createLicense_exposed(
            tokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            true,
            true,
            terms,
            false
        );
        uint256 licenseId = _verifyLicense(tokenId, termsProcessor);
        LicenseRegistry licenseRegistry = LicenseRegistry(rightsManager.getLicenseRegistry());
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);

    }
    /**
    function test_internal_create_license_nonRootLicense_minting() public {
        uint256 tokenId = 1;
        rightsManager.mint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        MockTermsProcessor termsProcessor = new MockTermsProcessor();
        IERC5218.TermsProcessorConfig memory terms = IERC5218.TermsProcessorConfig({
            processor: termsProcessor,
            data: abi.encode("terms")
        });
        // TODO test events
        rightsManager.createLicense_exposed(
            tokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            true,
            true,
            terms,
            false
        );
        uint256 licenseId = _verifyLicense(tokenId, termsProcessor);
        LicenseRegistry licenseRegistry = LicenseRegistry(rightsManager.getLicenseRegistry());
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);

    }
    */

    function test_revert_internal_createLicense_zeroRevoker() public {}
    function test_revert_internal_createLicense_nonExistentId() public {}
    function test_revert_internal_createLicense_alreadyHasRootLicense() public {}
    function test_revert_internal_createLicense_notOwnerOfParentLicense() public {}
    function test_revert_internal_createLicense_inactiveParentLicense() public {}
    function test_revert_internal_createLicense_cannotSublicense() public {}
    function test_revert_internal_createLicense_commercialTermsMismatch() public {}
    function test_revert_internal_createLicense_nonCommercialTermsMismatch() public {}
    function test_revert_internal_createLicense_termsProcessorUnsupportedInterface() public {}

    function _verifyLicense(uint256 tokenId, MockTermsProcessor termsProcessor) private returns(uint256) {
        uint256 licenseId = rightsManager.getLicenseIdByTokenId(tokenId, true);
        assertEq(licenseId, 1);
        assertEq(rightsManager.getLicenseTokenId(licenseId), tokenId);
        assertEq(rightsManager.getParentLicenseId(licenseId), 0);
        assertTrue(rightsManager.isLicenseActive(licenseId));
        assertEq(rightsManager.getLicenseURI(licenseId), "licenseUri");
        (RightsManager.License memory license, address owner) = rightsManager.getLicense(licenseId);
        assertEq(owner, licenseHolder, "internal method will not create ipasset, but we minted in RightsManagerHarness");
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

}

/*
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
    }



}
*/