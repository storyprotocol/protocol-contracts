// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/ip-accounts/IIPAccount.sol";
import "contracts/ip-accounts/IPAccountImpl.sol";
import "contracts/ip-accounts/IPAccountRegistry.sol";
import "contracts/modules/royalties/RoyaltyDistributor.sol";
import "contracts/modules/royalties/RoyaltyNFT.sol";
import "contracts/modules/royalties/ISplitMain.sol";
import "contracts/modules/royalties/policies/MutableRoyaltyProportionPolicy.sol";
import "contracts/modules/licensing/terms/RoyaltyTermsProcessor.sol";
import '../utils/BaseTest.sol';
import '../mocks/MockLicensingModule.sol';
import '../mocks/MockTermsProcessor.sol';
import '../mocks/RightsManagerHarness.sol';
import "../mocks/MockERC721.sol";
import "../mocks/MockERC20.sol";
import "contracts/errors/General.sol";

contract E2ETest is BaseTest {
    RoyaltyDistributor public royaltyDistributor;
    IPAccountRegistry public registry;
    IPAccountImpl public implementation;
    RoyaltyNFT public royaltyNft;
    ISplitMain public splitMain;
    MutableRoyaltyProportionPolicy public mutablePolicy;
    MockERC20 public mERC20;
    RoyaltyTermsProcessor royaltyTermsProcessor;

    function setUp() virtual override public {
        string memory mainnetRpc;
        try vm.envString("MAINNET_RPC_URL") returns (string memory rpcUrl) {
            mainnetRpc = rpcUrl;
        } catch {
            mainnetRpc = "https://eth-mainnet.g.alchemy.com/v2/demo";
        }
        console.log(mainnetRpc);
        uint256 mainnetFork = vm.createFork(mainnetRpc);
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
        console.log(block.number);
        // using the existing SplitMain
        splitMain = ISplitMain(0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE);
        royaltyNft = new RoyaltyNFT(address(splitMain));
        implementation = new IPAccountImpl();
        registry = new IPAccountRegistry(address(implementation));
        royaltyDistributor = new RoyaltyDistributor(address(registry), address(royaltyNft));
        mutablePolicy = new MutableRoyaltyProportionPolicy(address(royaltyNft));
        mERC20 = new MockERC20("Royalty Token", "RTK", 18);
        deployProcessors = false;
        super.setUp();
        royaltyTermsProcessor = new RoyaltyTermsProcessor(address(ipAssetRegistry), address(royaltyDistributor));
    }

    function test_e2e() public {
        uint256 rootIpAssetId = ipAssetRegistry.createIPAsset(
            IPAsset(1),
            "rootIPAssetName",
            "The root IP Asset description",
            "http://root.ipasset.media.url",
            alice,
            0
        );

        uint256 ipAssetId = ipAssetRegistry.createIPAsset(
            IPAsset(1),
            "DerivativeIPAssetName",
            "The derivative IP Asset description",
            "http://derivative.ipasset.media.url",
            bob,
            rootIpAssetId
        );

        uint256 parentLicenseId = ipAssetRegistry.getLicenseIdByTokenId(rootIpAssetId, true);
        address rootIpAccount = registry.createAccount(block.chainid, address(ipAssetRegistry), rootIpAssetId, "");
        address derivativeIpAccount = registry.createAccount(block.chainid, address(ipAssetRegistry), ipAssetId, "");
        // build Royalty Terms Config
        address[] memory royaltyAccounts = new address[](2);
        uint32[] memory royaltyPercentages = new uint32[](2);
        royaltyAccounts[0] = rootIpAccount;
        royaltyAccounts[1] = derivativeIpAccount;
        royaltyPercentages[0] = 100000;
        royaltyPercentages[1] = 900000;
        RoyaltyTermsConfig memory termsConfig = RoyaltyTermsConfig({
            payerNftContract: address(ipAssetRegistry),
            payerTokenId: ipAssetId,
            accounts: royaltyAccounts,
            allocationPercentages : royaltyPercentages,
            isExecuted: false
        });

        // Create license
        vm.prank(alice);
        uint256 licenseId = ipAssetRegistry.createLicense(
            ipAssetId,
            parentLicenseId,
            alice,
            "https://derivative.commercial.license.uri",
            revoker,
            true,
            true,
            IERC5218.TermsProcessorConfig({
                processor: royaltyTermsProcessor,
                data: abi.encode(termsConfig)
            })
        );
        bool commercial = true;
        (RightsManager.License memory license, address owner) = ipAssetRegistry.getLicense(licenseId);
        assertEq(licenseId, 4);
        assertEq(owner, alice);
        assertEq(license.active, true);
        assertEq(license.canSublicense, true);
        assertEq(license.commercial, commercial);
        assertEq(license.parentLicenseId, parentLicenseId);
        assertEq(license.tokenId, ipAssetId);
        assertEq(license.revoker, revoker);
        assertEq(license.uri, "https://derivative.commercial.license.uri");
        assertEq(address(license.termsProcessor), address(royaltyTermsProcessor));
        assertEq(license.termsData, abi.encode(termsConfig));
        assertEq(licenseRegistry.ownerOf(licenseId), alice);

        royaltyDistributor.setRoyaltyPolicy(address(ipAssetRegistry), ipAssetId, address(mutablePolicy), "");

        // execute license terms
        vm.startPrank(alice);
        ipAssetRegistry.executeTerms(licenseId);
        licenseRegistry.transferFrom(alice, bob, licenseId);
        vm.stopPrank();

        assertEq(ipAssetRegistry.isLicenseActive(licenseId), true);
        assertEq(royaltyNft.balanceOf(rootIpAccount, royaltyNft.toTokenId(derivativeIpAccount)), 100000);
        assertEq(royaltyNft.balanceOf(derivativeIpAccount, royaltyNft.toTokenId(derivativeIpAccount)), 900000);

        mERC20.mint(10000);
        mERC20.transfer(derivativeIpAccount, 10000);
        assertEq(mERC20.balanceOf(derivativeIpAccount), 10000);
        vm.startPrank(derivativeIpAccount);
        mERC20.approve(address(royaltyNft), 10000);
        vm.stopPrank();
        royaltyDistributor.distribute(address(ipAssetRegistry), ipAssetId, address(mERC20));
        // splitMain always reserve 1 as minimal balance
        assertEq(splitMain.getERC20Balance(rootIpAccount, mERC20), 999);
        assertEq(splitMain.getERC20Balance(derivativeIpAccount, mERC20), 8999);
        assertEq(mERC20.balanceOf(rootIpAccount), 0);
        assertEq(mERC20.balanceOf(derivativeIpAccount), 0);

        royaltyDistributor.claim(rootIpAccount, address(mERC20));
        assertEq(mERC20.balanceOf(rootIpAccount), 998);
        royaltyDistributor.claim(derivativeIpAccount, address(mERC20));
        assertEq(mERC20.balanceOf(derivativeIpAccount),8998);
    }

    function _getLicensingConfig() view internal virtual override returns (ILicensingModule.FranchiseConfig memory) {
        return ILicensingModule.FranchiseConfig({
            nonCommercialConfig: ILicensingModule.IpAssetConfig({
            canSublicense: true,
            franchiseRootLicenseId: 0
        }),
            nonCommercialTerms: IERC5218.TermsProcessorConfig({
            processor: nonCommercialTermsProcessor,
            data: abi.encode("nonCommercial")
        }),
            commercialConfig: ILicensingModule.IpAssetConfig({
            canSublicense: true,
            franchiseRootLicenseId: 0
        }),
            commercialTerms: IERC5218.TermsProcessorConfig({
            processor: commercialTermsProcessor,
            data: abi.encode("commercial")
        }),
            rootIpAssetHasCommercialRights: true,
            revoker: revoker,
            commercialLicenseUri: "uriuri"
        });
    }
}
