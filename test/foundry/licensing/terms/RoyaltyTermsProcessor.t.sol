// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import "contracts/errors/General.sol";
import "contracts/modules/licensing/terms/RoyaltyTermsProcessor.sol";
import "test/foundry/mocks/MockRoyaltyDistributor.sol";

contract RoyaltyTermsProcessorTest is BaseTest {
    address licenseHolder = address(0x888888);
    RoyaltyTermsProcessor processor;
    uint256 licenseId;
    uint256 ipAssetId;
    uint256 parentLicenseId;
    MockRoyaltyDistributor royaltyDistributor;

    address[] accounts;
    uint32[] allocationPercentages;


    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
        royaltyDistributor = new MockRoyaltyDistributor();
        ipAssetId = ipAssetRegistry.createIPAsset(IPAsset(1), "name", "description", "mediaUrl", licenseHolder, 0);
        parentLicenseId = ipAssetRegistry.getLicenseIdByTokenId(ipAssetId, false);
        processor = new RoyaltyTermsProcessor(address(ipAssetRegistry), address(royaltyDistributor));
    }

    function test_revert_execute_terms_unauthorized() public {
        bytes memory data = abi.encode(1);
        vm.expectRevert(Unauthorized.selector);
        processor.executeTerms(data);
    }

    function test_revert_execute_terms_empty_accounts() public {
        RoyaltyTermsConfig memory termsConfig = RoyaltyTermsConfig({
            payerNftContract: address(ipAssetRegistry),
            payerTokenId: ipAssetId,
            accounts: accounts,
            allocationPercentages : allocationPercentages,
            isExecuted: false
        });
        vm.prank(address(ipAssetRegistry));
        vm.expectRevert(EmptyArray.selector);
        processor.executeTerms(abi.encode(termsConfig));
    }

    function test_revert_execute_terms_mismatch_accounts_allocations() public {
        accounts = [address(0x888888)];
        allocationPercentages = [100000, 900000];
        RoyaltyTermsConfig memory termsConfig = RoyaltyTermsConfig({
            payerNftContract: address(ipAssetRegistry),
            payerTokenId: ipAssetId,
            accounts: accounts,
            allocationPercentages : allocationPercentages,
            isExecuted: false
        });
        vm.prank(address(ipAssetRegistry));
        vm.expectRevert(LengthMismatch.selector);
        processor.executeTerms(abi.encode(termsConfig));
    }

    function test_execute_terms_start_on_license_creation() public {
        accounts = [address(0x777777), address(0x888888)];
        allocationPercentages = [100000, 900000];
        RoyaltyTermsConfig memory config = RoyaltyTermsConfig({
            payerNftContract: address(ipAssetRegistry),
            payerTokenId: ipAssetId,
            accounts: accounts,
            allocationPercentages : allocationPercentages,
            isExecuted: false
        });

        IERC5218.TermsProcessorConfig memory termsConfig = IERC5218.TermsProcessorConfig({
            processor: processor,
            data: abi.encode(config)
        });
        
        assertFalse(processor.termsExecutedSuccessfully(abi.encode(config)), "terms should be inactive before start time");

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
        assertTrue(ipAssetRegistry.isLicenseActive(licenseId), "execution terms should make license active");
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(licenseId);
        assertEq(owner, licenseHolder);
        assertTrue(processor.termsExecutedSuccessfully(license.termsData), "execution terms should executed successfully.");
    }
}
