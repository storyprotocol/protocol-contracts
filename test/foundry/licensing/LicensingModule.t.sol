// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import '../mocks/MockLicensingModule.sol';
import '../mocks/MockTermsProcessor.sol';
import { Errors } from "contracts/lib/Errors.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";

contract LicensingModuleTest is BaseTest {

    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
    }

    function test_setUp() public {
        assertEq(licensingModule.getNonCommercialLicenseURI(), NON_COMMERCIAL_LICENSE_URI);
    }

    function test_configIPAssetGroup() public {
        vm.startPrank(franchiseOwner);
        Licensing.TermsProcessorConfig memory termsConfig = Licensing.TermsProcessorConfig({
            processor: commercialTermsProcessor,
            data: abi.encode("root")
        });

        uint256 rootLicenseId = ipAssetGroup.createIPAssetGroupRootLicense(1, franchiseOwner, "commercial_uri_root", revoker, true, true, termsConfig);
        assertEq(licenseRegistry.ownerOf(rootLicenseId), franchiseOwner);
        assertEq(rootLicenseId, 1);

        Licensing.IPAssetGroupConfig memory config = _getLicensingConfig();
        config.revoker = address(0x5656565);
        config.commercialConfig.franchiseRootLicenseId = rootLicenseId;
        config.commercialTerms.data = abi.encode("bye");
        config.nonCommercialTerms.data = abi.encode("hi");
        
        licensingModule.configureIPAssetGroupLicensing(1, config);
        Licensing.IPAssetGroupConfig memory configResult = licensingModule.getIPAssetGroupConfig(1);
        assertEq(configResult.nonCommercialConfig.canSublicense, true);
        assertEq(configResult.nonCommercialConfig.franchiseRootLicenseId, 0);
        assertEq(address(configResult.nonCommercialTerms.processor), address(nonCommercialTermsProcessor));
        assertEq(configResult.nonCommercialTerms.data, abi.encode("hi"));
        assertEq(configResult.commercialConfig.canSublicense, false);
        assertEq(configResult.commercialConfig.franchiseRootLicenseId, 1);
        assertEq(address(configResult.commercialTerms.processor), address(commercialTermsProcessor));
        assertEq(configResult.commercialTerms.data, abi.encode("bye"));
        assertEq(configResult.rootIpAssetHasCommercialRights, false);
        assertEq(configResult.revoker, address(0x5656565));
        vm.stopPrank();
    }

    function test_revert_nonAuthorizedConfigSetter() public {
        vm.expectRevert(Errors.Unauthorized.selector);
        licensingModule.configureIPAssetGroupLicensing(1, LibMockIPAssetGroupConfig.getMockIPAssetGroupConfig());
    }

    function test_revert_nonExistingIPAssetGroup() public {
        vm.expectRevert("ERC721: invalid token ID");
        licensingModule.configureIPAssetGroupLicensing(2, LibMockIPAssetGroupConfig.getMockIPAssetGroupConfig());
    }

    function test_revert_zeroRevokerAddress() public {
        vm.startPrank(franchiseOwner);
        Licensing.IPAssetGroupConfig memory config = LibMockIPAssetGroupConfig.getMockIPAssetGroupConfig();
        config.revoker = address(0);
        vm.expectRevert(Errors.LicensingModule_ZeroRevokerAddress.selector);
        licensingModule.configureIPAssetGroupLicensing(1, config);
        vm.stopPrank();
    }

    function test_revert_rootLicenseNotActiveCommercial() public {
        
        Licensing.TermsProcessorConfig memory termsConfig = Licensing.TermsProcessorConfig({
            processor: commercialTermsProcessor,
            data: abi.encode("root")
        });

        vm.prank(franchiseOwner);
        uint256 rootLicenseId = ipAssetGroup.createIPAssetGroupRootLicense(1, franchiseOwner, "commercial_uri_root", revoker, true, true, termsConfig);
        
        commercialTermsProcessor.setSuccess(false);
        
        Licensing.IPAssetGroupConfig memory config = _getLicensingConfig();
        config.commercialConfig.franchiseRootLicenseId = rootLicenseId;
        vm.startPrank(franchiseOwner);
        vm.expectRevert(abi.encodeWithSignature("LicensingModule_RootLicenseNotActive(uint256)", 1));
        licensingModule.configureIPAssetGroupLicensing(1, config);
        vm.stopPrank();
        
    }

}
