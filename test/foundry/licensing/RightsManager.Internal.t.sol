// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import '../mocks/MockLicensingModule.sol';
import '../mocks/MockTermsProcessor.sol';
import '../mocks/RightsManagerHarness.sol';
import "../mocks/MockERC721.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";

contract RightsManagerInternalTest is Test, ProxyHelper {

    MockERC721 mockFranchiseRegistry;
    RightsManagerHarness rightsManager;
    address constant mockEventEmitter = address(0x1234567);
    address constant mockLicensingModule = address(0x23445);
    address constant mockCollectModule = address(0x13371);
    address constant licenseHolder = address(0x8073465);
    address constant revoker = address(0x123456722222);
    
    function setUp() public {
        mockFranchiseRegistry = new MockERC721();
        RightsManagerHarness impl = new RightsManagerHarness(mockEventEmitter, mockLicensingModule, address(mockFranchiseRegistry), mockCollectModule);
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
        LicenseRegistry licenseRegistry = new LicenseRegistry(address(rightsManager), "name", "symbol");
        rightsManager.setLicenseRegistry(address(licenseRegistry));
    }

    function test_setup() public {
        assertEq(address(rightsManager.FRANCHISE_REGISTRY()), address(mockFranchiseRegistry));
        assertEq(rightsManager.name(), "name");
        assertEq(rightsManager.symbol(), "symbol");
    }

    function test_revert_transfer_sublicense() public {
        vm.expectRevert(Errors.Unauthorized.selector);
        rightsManager.transferSublicense(1, address(0x123456));
    }

    function test_internal_create_license_rootLicense_notmockMinting() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 0;
        (Licensing.TermsProcessorConfig memory terms, MockTermsProcessor termsProcessor) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // TODO test events
        uint256 licenseId = rightsManager.createLicense_exposed(
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
        assertEq(licenseId, rightsManager.getLicenseIdByTokenId(tokenId, true));
        _verifyLicense(licenseId, parentLicenseId, tokenId, termsProcessor, true, true);
        ILicenseRegistry licenseRegistry = ILicenseRegistry(rightsManager.getLicenseRegistry());
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);

    }

    function test_internal_create_license_rootLicense_mockMinting() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 0;
        (Licensing.TermsProcessorConfig memory terms, MockTermsProcessor termsProcessor) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // TODO test events
        uint256 licenseId = rightsManager.createLicense_exposed(
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
        assertEq(licenseId, rightsManager.getLicenseIdByTokenId(tokenId, true), "wtf");
        _verifyLicense(licenseId, parentLicenseId, tokenId, termsProcessor, true, true);
        ILicenseRegistry licenseRegistry = ILicenseRegistry(rightsManager.getLicenseRegistry());
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);
    }

    function test_internal_create_license_nonRootLicense_notmockMinting() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        (Licensing.TermsProcessorConfig memory terms, MockTermsProcessor termsProcessor) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
        uint256 parentLicenseId = rightsManager.createLicense_exposed(
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
        // mockMint derivative ip
        uint256 nextTokenId = tokenId + 1;
        rightsManager.mockMint(licenseHolder, nextTokenId);
        // mockMint sublicense
        uint256 licenseId = rightsManager.createLicense_exposed(
            nextTokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            true,
            true,
            terms,
            false
        );
        assertEq(licenseId, rightsManager.getLicenseIdByTokenId(nextTokenId, true));
        _verifyLicense(licenseId, parentLicenseId, nextTokenId, termsProcessor, true, true);
        ILicenseRegistry licenseRegistry = ILicenseRegistry(rightsManager.getLicenseRegistry());
        vm.expectRevert("ERC721: invalid token ID");
        licenseRegistry.ownerOf(licenseId);

    }
    
    function test_internal_create_license_nonRootLicense_mockMinting() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        (Licensing.TermsProcessorConfig memory terms, MockTermsProcessor termsProcessor) = LibMockFranchiseConfig.getTermsProcessorConfig();
        // mockMint root
        uint256 parentLicenseId = rightsManager.createLicense_exposed(
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
        uint256 licenseId = rightsManager.createLicense_exposed(
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
        _verifyLicense(licenseId, parentLicenseId, tokenId, termsProcessor, true, true);
        ILicenseRegistry licenseRegistry = ILicenseRegistry(rightsManager.getLicenseRegistry());
        assertEq(licenseRegistry.ownerOf(licenseId), licenseHolder);
    }

    function test_revert_internal_createLicense_zeroRevoker() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 0;
        (Licensing.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
        vm.expectRevert(Errors.RightsManager_ZeroRevokerAddress.selector);
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
        (Licensing.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
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
        (Licensing.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
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
        vm.expectRevert(Errors.RightsManager_AlreadyHasRootLicense.selector);
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
        (Licensing.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
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
        vm.expectRevert(Errors.RightsManager_NotOwnerOfParentLicense.selector);
        rightsManager.createLicense_exposed(
            tokenId,
            parentLicenseId,
            address(0x123456),
            "licenseUri",
            revoker,
            true,
            true,
            terms,
            true
        );
    }

    function test_revert_internal_createLicense_inactiveParentLicense() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (Licensing.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
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
        vm.expectRevert(Errors.RightsManager_InactiveParentLicense.selector);
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
    }

    function test_revert_internal_createLicense_cannotSublicense() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (Licensing.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
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
        vm.expectRevert(Errors.RightsManager_CannotSublicense.selector);
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
    }

    function test_revert_internal_createLicense_commercialTermsMismatch() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (Licensing.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
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
        vm.expectRevert(Errors.RightsManager_CommercialTermsMismatch.selector);
        rightsManager.createLicense_exposed(
            tokenId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            true,
            terms,
            true
        );
    }

    function test_revert_internal_createLicense_nonCommercialTermsMismatch() public {
        uint256 tokenId = 1;
        rightsManager.mockMint(licenseHolder, tokenId);
        uint256 parentLicenseId = 1;
        (Licensing.TermsProcessorConfig memory terms,) = LibMockFranchiseConfig.getTermsProcessorConfig();
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
        vm.expectRevert(Errors.RightsManager_CommercialTermsMismatch.selector);
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
        // Uncomment this if we ever allow commercial sublicenses attached to children tokenIds
        /*
        vm.expectRevert(Errors.RightsManager_CommercialTermsMismatch.selector);
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
        );*/
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
            Licensing.TermsProcessorConfig({
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

    function _verifyLicense(uint256 licenseId, uint256 parentLicenseId, uint256 tokenId, MockTermsProcessor termsProcessor, bool canSublicense, bool commercial) private {
        assertEq(rightsManager.getLicenseTokenId(licenseId), tokenId, "license tokenId");
        assertEq(rightsManager.getParentLicenseId(licenseId), parentLicenseId, "license parentLicenseId");
        assertTrue(rightsManager.isLicenseActive(licenseId), "license active");
        assertEq(rightsManager.getLicenseURI(licenseId), "licenseUri");
        (Licensing.License memory license, address owner) = rightsManager.getLicense(licenseId);
        assertEq(owner, licenseHolder, "internal method will not create ipasset, but we mockMinted in RightsManagerHarness");
        assertEq(license.active, true, "license active");
        assertEq(license.canSublicense, canSublicense, "license canSublicense");
        assertEq(license.commercial, commercial, "license commercial");
        assertEq(license.parentLicenseId, parentLicenseId, "license parentLicenseId");
        assertEq(license.tokenId, tokenId, "license tokenId");
        assertEq(license.revoker, revoker, "license revoker");
        assertEq(license.uri, "licenseUri", "license uri");
        assertEq(address(license.termsProcessor), address(termsProcessor), "license termsProcessor");
        assertEq(license.termsData, abi.encode("terms"), "license termsData");
    }
}
