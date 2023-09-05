// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import "contracts/errors/General.sol";
import "contracts/modules/licensing/terms/TimeTermsProcessor.sol";
import "contracts/modules/timing/LibDuration.sol";

contract LicenseRegistryTest is BaseTest {

    address licenseHolder = address(0x888888);
    TimeTermsProcessor processor;
    uint256 licenseId;
    uint256 ipAssetId;
    uint256 parentLicenseId;

    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
        ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaUrl", licenseHolder, 0);
        parentLicenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, false);
        processor = new TimeTermsProcessor(address(ipAssetRegistry));
    }

    function test_revert_execute_terms_unauthorized() public {
        bytes memory data = abi.encode(1);
        vm.expectRevert(Unauthorized.selector);
        processor.executeTerms(data);
    }

    function test_execute_terms_start_on_license_creation() public {
        uint64 ttl = 1000;
        uint64 startTime = uint64(block.timestamp) + 100;
        address renewer = address(0);

        LibDuration.TimeConfig memory config = LibDuration.TimeConfig(
            ttl,
            startTime,
            renewer
        );
        IERC5218.TermsProcessorConfig memory termsConfig = IERC5218.TermsProcessorConfig({
            processor: processor,
            data: abi.encode(config)
        });
        
        assertFalse(processor.tersmExecutedSuccessfully(abi.encode(config)), "terms should be inactive before start time");

        vm.prank(licenseHolder);
        licenseId = ipAssetRegistry.createLicense(
            ipAssetId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            false,
            termsConfig
        );
        vm.prank(licenseHolder);
        ipAssetRegistry.executeTerms(licenseId);
        assertFalse(ipAssetRegistry.isLicenseActive(licenseId), "execution is a noop if start time set");
        assertFalse(processor.tersmExecutedSuccessfully(abi.encode(config)), "execution is a noop if start time set");
        vm.warp(startTime + 100);
        assertTrue(ipAssetRegistry.isLicenseActive(licenseId), "license should be active after start time");
        assertTrue(processor.tersmExecutedSuccessfully(abi.encode(config)), "terms should be active after start time");
        vm.warp(startTime + ttl + 1);
        assertFalse(processor.tersmExecutedSuccessfully(abi.encode(config)), "terms should be inactive after ttl");
        assertFalse(ipAssetRegistry.isLicenseActive(licenseId), "license should be inactive after ttl");
        
    }

    function test_terms_always_false_if_not_started() public {
        uint64 ttl = 1000;
        uint64 startTime = 0; // unset so it fills with block.timestamp in terms execution
        address renewer = address(0);

        LibDuration.TimeConfig memory config = LibDuration.TimeConfig(
            ttl,
            startTime,
            renewer
        );
        IERC5218.TermsProcessorConfig memory termsConfig = IERC5218.TermsProcessorConfig({
            processor: processor,
            data: abi.encode(config)
        });
        
        assertFalse(processor.tersmExecutedSuccessfully(abi.encode(config)));

        vm.prank(licenseHolder);
        licenseId = ipAssetRegistry.createLicense(
            ipAssetId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            false,
            termsConfig
        );
        assertFalse(ipAssetRegistry.isLicenseActive(licenseId));
        assertFalse(processor.tersmExecutedSuccessfully(abi.encode(config)));
        vm.warp(block.timestamp + 100);
        assertFalse(ipAssetRegistry.isLicenseActive(licenseId));
        assertFalse(processor.tersmExecutedSuccessfully(abi.encode(config)));
        vm.warp(block.timestamp + ttl + 1);
        assertFalse(processor.tersmExecutedSuccessfully(abi.encode(config)));
        assertFalse(ipAssetRegistry.isLicenseActive(licenseId));
        
    }

    function test_execute_terms_start_license_countdown() public {
        uint64 ttl = 1000;
        uint64 startTime = 0; // unset so it fills with block.timestamp in terms execution
        address renewer = address(0);

        LibDuration.TimeConfig memory config = LibDuration.TimeConfig(
            ttl,
            startTime,
            renewer
        );
        IERC5218.TermsProcessorConfig memory termsConfig = IERC5218.TermsProcessorConfig({
            processor: processor,
            data: abi.encode(config)
        });
        
        assertFalse(processor.tersmExecutedSuccessfully(abi.encode(config)), "terms should be inactive before start time");

        vm.prank(licenseHolder);
        licenseId = ipAssetRegistry.createLicense(
            ipAssetId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            false,
            termsConfig
        );
        assertFalse(ipAssetRegistry.isLicenseActive(licenseId), "terms not executed yet");
        vm.prank(licenseHolder);
        ipAssetRegistry.executeTerms(licenseId);
        assertTrue(ipAssetRegistry.isLicenseActive(licenseId), "license started after terms execution");
        vm.warp(block.timestamp + 100);
        assertTrue(ipAssetRegistry.isLicenseActive(licenseId), "license should be active after start time");
        vm.warp(block.timestamp + ttl + 1);
        assertFalse(ipAssetRegistry.isLicenseActive(licenseId), "license should be inactive after ttl");
        
    }

   
}
