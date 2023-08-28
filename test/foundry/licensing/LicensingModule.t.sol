// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import '../mocks/MockLicensingModule.sol';
import '../mocks/MockTermsProcessor.sol';
import "contracts/errors/General.sol";

contract LicensingModuleTest is BaseTest {

    ITermsProcessor public termsProcessor1;
    ITermsProcessor public termsProcessor2;

    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
        termsProcessor1 = new MockTermsProcessor();
        termsProcessor2 = new MockTermsProcessor();
    }

    function test_setUp() public {
        assertEq(licensingModule.getNonCommercialLicenseURI(), NON_COMMERCIAL_LICENSE_URI);
    }

    function test_revert_nonAuthorizedConfigSetter() public {
        vm.expectRevert(Unauthorized.selector);
        licensingModule.configureFranchiseLicensing(1, LibMockFranchiseConfig.getMockFranchiseConfig());
    }

    function test_revert_nonExistingFranchise() public {
        vm.expectRevert("ERC721: invalid token ID");
        licensingModule.configureFranchiseLicensing(2, LibMockFranchiseConfig.getMockFranchiseConfig());
    }
    

    function test_configFranchise() public {
        vm.startPrank(franchiseOwner);
        IERC5218.TermsProcessorConfig memory termsConfig = IERC5218.TermsProcessorConfig({
            processor: termsProcessor1,
            data: abi.encode("root")
        });
        uint256 rootLicenseId = ipAssetRegistry.createFranchiseRootLicense(1, franchiseOwner, "commercial_uri_root", revoker, true, true, termsConfig);

        ILicensingModule.FranchiseConfig memory config = ILicensingModule.FranchiseConfig({
            nonCommercialConfig: ILicensingModule.IpAssetConfig({
                canSublicense: true,
                franchiseRootLicenseId: 0
            }),
            nonCommercialTerms: IERC5218.TermsProcessorConfig({
                processor: termsProcessor1,
                data: abi.encode("hi")
            }),
            commercialConfig: ILicensingModule.IpAssetConfig({
                canSublicense: false,
                franchiseRootLicenseId: rootLicenseId
            }),
            commercialTerms: IERC5218.TermsProcessorConfig({
                processor: termsProcessor2,
                data: abi.encode("bye")
            }),
            rootIpAssetHasCommercialRights: false,
            revoker: address(0x5656565),
            commercialLicenseUri: "uriuri"
        });
        
        licensingModule.configureFranchiseLicensing(1, config);
        ILicensingModule.FranchiseConfig memory configResult = licensingModule.getFranchiseConfig(1);
        assertEq(configResult.nonCommercialConfig.canSublicense, true);
        assertEq(configResult.nonCommercialConfig.franchiseRootLicenseId, 0);
        assertEq(address(configResult.nonCommercialTerms.processor), address(termsProcessor1));
        assertEq(configResult.nonCommercialTerms.data, abi.encode("hi"));
        assertEq(configResult.commercialConfig.canSublicense, false);
        assertEq(configResult.commercialConfig.franchiseRootLicenseId, 1);
        assertEq(address(configResult.commercialTerms.processor), address(termsProcessor2));
        assertEq(configResult.commercialTerms.data, abi.encode("bye"));
        assertEq(configResult.rootIpAssetHasCommercialRights, false);
        assertEq(configResult.revoker, address(0x5656565));
        vm.stopPrank();
    }



}
