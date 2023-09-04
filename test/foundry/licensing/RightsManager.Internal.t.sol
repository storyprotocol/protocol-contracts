// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import '../mocks/MockLicensingModule.sol';
import '../mocks/MockTermsProcessor.sol';
import '../mocks/RightsManagerHarness.sol';
import "../mocks/MockERC721.sol";
import "contracts/errors/General.sol"; 


contract RightsManagerInternalTest is Test, ProxyHelper {

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

    function test_internal_create_license_rootLicense_notmockMinting() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 0;
        (IERC5218.TermsProcessorConfig memory terms, MockTermsProcessor termsProcessor) = LibMockFranchiseConfig.getTermsProcessorConfig();
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

    function test_internal_create_license_rootLicense_mockMinting() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 0;
        (IERC5218.TermsProcessorConfig memory terms, MockTermsProcessor termsProcessor) = LibMockFranchiseConfig.getTermsProcessorConfig();
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

    function test_internal_create_license_nonRootLicense_notmockMinting() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (IERC5218.TermsProcessorConfig memory terms, MockTermsProcessor termsProcessor) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
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
        // mockMint sublicense
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
    
    function test_internal_create_license_nonRootLicense_mockMinting() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (IERC5218.TermsProcessorConfig memory terms, MockTermsProcessor termsProcessor) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
        rightsManager.createLicense_exposed(
            tokenId,
            0,
            licenseHolder,
            "licenseUri",
            revoker,
            true,
            true,
            terms,
            true
        );
        // mockMint sublicense
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

    function test_revert_internal_createLicense_zeroRevoker() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 0;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        vm.expectRevert(RightsManager.ZeroRevokerAddress.selector);
        rightsManager.createLicense_exposed(
            tokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            address(0),
            true,
            true,
            terms,
            false
        );
    }

    function test_revert_internal_createLicense_nonExistentId() public {
        uint256 tokenId = 1;
        uint256 parentLicenseId = 0;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        vm.expectRevert(abi.encodeWithSignature("NonExistentID(uint256)", 1));
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
    }

    function test_revert_internal_createLicense_alreadyHasRootLicense() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 0;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
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
        // mockMint root again
        vm.expectRevert(RightsManager.AlreadyHasRootLicense.selector);
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
    }

    function test_revert_internal_createLicense_notOwnerOfParentLicense() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
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
        // mockMint sublicense
        vm.expectRevert(RightsManager.NotOwnerOfParentLicense.selector);
        rightsManager.createLicense_exposed(
            tokenId,
            parentLicenseId,
            address(0x123456),
            "licenseUri",
            revoker,
            true,
            true,
            terms,
            false
        );
    }

    function test_revert_internal_createLicense_inactiveParentLicense() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
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
        
        vm.prank(revoker);
        rightsManager.revokeLicense(parentLicenseId);

        // mockMint sublicense
        vm.expectRevert(RightsManager.InactiveParentLicense.selector);
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
    }

    function test_revert_internal_createLicense_cannotSublicense() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
        rightsManager.createLicense_exposed(
            tokenId,
            0,
            licenseHolder,
            "licenseUri",
            revoker,
            true,
            false,
            terms,
            false
        );
        // mockMint sublicense
        vm.expectRevert(RightsManager.CannotSublicense.selector);
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
    }

    function test_revert_internal_createLicense_commercialTermsMismatch() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
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
        // mockMint sublicense
        vm.expectRevert(RightsManager.CommercialTermsMismatch.selector);
        rightsManager.createLicense_exposed(
            tokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            true,
            terms,
            false
        );
    }

    function test_revert_internal_createLicense_nonCommercialTermsMismatch() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (IERC5218.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
        rightsManager.createLicense_exposed(
            tokenId,
            0,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            true,
            terms,
            false
        );
        // mockMint sublicense
        vm.expectRevert(RightsManager.CommercialTermsMismatch.selector);
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
    }

    function test_revert_internal_createLicense_termsProcessorUnsupportedInterface() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        
        vm.expectRevert(abi.encodeWithSignature("UnsupportedInterface(string)", "ITermsProcessor"));
        // mockMint root
        rightsManager.createLicense_exposed(
            tokenId,
            0,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            true,
            IERC5218.TermsProcessorConfig({
                processor: ITermsProcessor(address(rightsManager)),
                data: abi.encode("terms")
            }),
            false
        );
    }

    function test_revert_unknown_license() public {
        vm.expectRevert("ERC721: invalid token ID");
        rightsManager.getLicense(222);
        vm.expectRevert("ERC721: invalid token ID");
        rightsManager.getLicense(0);
    }

    function _verifyLicense(uint256 tokenId, MockTermsProcessor termsProcessor) private returns(uint256) {
        uint256 licenseId = rightsManager.getLicenseIdByTokenId(tokenId, true);
        assertEq(licenseId, 1);
        assertEq(rightsManager.getLicenseTokenId(licenseId), tokenId);
        assertEq(rightsManager.getParentLicenseId(licenseId), 0);
        assertTrue(rightsManager.isLicenseActive(licenseId));
        assertEq(rightsManager.getLicenseURI(licenseId), "licenseUri");
        (RightsManager.License memory license, address owner) = rightsManager.getLicense(licenseId);
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
}
