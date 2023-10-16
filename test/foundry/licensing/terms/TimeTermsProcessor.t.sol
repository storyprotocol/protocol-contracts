// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import "contracts/errors/General.sol";
import "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
import "contracts/modules/licensing/terms/TimeTermsProcessor.sol";
import "contracts/modules/timing/LibDuration.sol";

contract LicenseRegistryTest is BaseTest {

    address licenseHolder = address(0x888888);
    ITermsProcessor processor;
    uint256 licenseId;
    uint256 ipAssetId;
    uint256 parentLicenseId;

    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
        ipAssetId = ipAssetGroup.createIpAsset(IPAsset.IPAssetType(1), "name", "description", "mediaUrl", licenseHolder, 0, "");
        parentLicenseId = ipAssetGroup.getLicenseIdByTokenId(ipAssetId, false);
        processor = getTermsProcessor();
    }

    function test_revert_execute_terms_unauthorized() public {
        bytes memory data = getTermsData(abi.encode(1));
        vm.expectRevert(Unauthorized.selector);
        processor.executeTerms(data);
    }

    function test_execute_terms_start_on_license_creation() public virtual {
        uint64 ttl = 1000;
        uint64 startTime = uint64(block.timestamp) + 100;
        address renewer = address(0);

        LibDuration.TimeConfig memory config = LibDuration.TimeConfig(
            ttl,
            startTime,
            renewer
        );
        bytes memory encodedConfig = getTermsConfig(abi.encode(config));

        Licensing.TermsProcessorConfig memory termsConfig = Licensing.TermsProcessorConfig({
            processor: processor,
            data: encodedConfig
        });

        assertFalse(processor.termsExecutedSuccessfully(encodedConfig), "terms should be inactive before start time");

        vm.prank(licenseHolder);
        licenseId = ipAssetGroup.createLicense(
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
        ipAssetGroup.executeTerms(licenseId);
        assertFalse(ipAssetGroup.isLicenseActive(licenseId), "execution is a noop if start time set");
        assertFalse(processor.termsExecutedSuccessfully(encodedConfig), "execution is a noop if start time set");
        vm.warp(startTime + 100);
        assertTrue(ipAssetGroup.isLicenseActive(licenseId), "license should be active after start time");
        assertTrue(processor.termsExecutedSuccessfully(encodedConfig), "terms should be active after start time");
        vm.warp(startTime + ttl + 1);
        assertFalse(processor.termsExecutedSuccessfully(encodedConfig), "terms should be inactive after ttl");
        assertFalse(ipAssetGroup.isLicenseActive(licenseId), "license should be inactive after ttl");

    }

    function test_terms_always_false_if_not_started() public virtual {
        uint64 ttl = 1000;
        uint64 startTime = 0; // unset so it fills with block.timestamp in terms execution
        address renewer = address(0);

        LibDuration.TimeConfig memory config = LibDuration.TimeConfig(
            ttl,
            startTime,
            renewer
        );
        bytes memory encodedConfig = getTermsConfig(abi.encode(config));
        Licensing.TermsProcessorConfig memory termsConfig = Licensing.TermsProcessorConfig({
            processor: processor,
            data: encodedConfig
        });

        assertFalse(processor.termsExecutedSuccessfully(encodedConfig));

        vm.prank(licenseHolder);
        licenseId = ipAssetGroup.createLicense(
            ipAssetId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            false,
            termsConfig
        );
        assertFalse(ipAssetGroup.isLicenseActive(licenseId));
        assertFalse(processor.termsExecutedSuccessfully(encodedConfig));
        vm.warp(block.timestamp + 100);
        assertFalse(ipAssetGroup.isLicenseActive(licenseId));
        assertFalse(processor.termsExecutedSuccessfully(encodedConfig));
        vm.warp(block.timestamp + ttl + 1);
        assertFalse(processor.termsExecutedSuccessfully(encodedConfig));
        assertFalse(ipAssetGroup.isLicenseActive(licenseId));

    }

    function test_execute_terms_start_license_countdown() public virtual {
        uint64 ttl = 1000;
        uint64 startTime = 0; // unset so it fills with block.timestamp in terms execution
        address renewer = address(0);

        LibDuration.TimeConfig memory config = LibDuration.TimeConfig(
            ttl,
            startTime,
            renewer
        );
        bytes memory encodedConfig = getTermsConfig(abi.encode(config));
        Licensing.TermsProcessorConfig memory termsConfig = Licensing.TermsProcessorConfig({
            processor: processor,
            data: encodedConfig
        });

        assertFalse(processor.termsExecutedSuccessfully(encodedConfig), "terms should be inactive before start time");

        vm.prank(licenseHolder);
        licenseId = ipAssetGroup.createLicense(
            ipAssetId,
            parentLicenseId,
            licenseHolder,
            "licenseUri",
            revoker,
            false,
            false,
            termsConfig
        );
        assertFalse(ipAssetGroup.isLicenseActive(licenseId), "terms not executed yet");
        vm.prank(licenseHolder);
        ipAssetGroup.executeTerms(licenseId);
        assertTrue(ipAssetGroup.isLicenseActive(licenseId), "license started after terms execution");
        vm.warp(block.timestamp + 100);
        assertTrue(ipAssetGroup.isLicenseActive(licenseId), "license should be active after start time");
        vm.warp(block.timestamp + ttl + 1);
        assertFalse(ipAssetGroup.isLicenseActive(licenseId), "license should be inactive after ttl");

    }

    function getTermsProcessor() internal virtual returns (ITermsProcessor) {
        return new TimeTermsProcessor(address(ipAssetGroup));
    }

    function getTermsData(bytes memory data) internal virtual returns (bytes memory) {
        return data;
    }

    function getTermsConfig(bytes memory config) internal virtual returns (bytes memory) {
        return config;
    }
}
