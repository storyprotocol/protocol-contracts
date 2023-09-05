// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/ip-accounts/IPAccountRegistry.sol";
import "test/foundry/mocks/MockIPAccount.sol";
import "contracts/modules/royalties/RoyaltyDistributor.sol";
import "contracts/modules/royalties/RoyaltyNFT.sol";
import "contracts/modules/royalties/ISplitMain.sol";
import "./mocks/MockSplitMain.sol";
import "test/foundry/mocks/MockSplitMain.sol";
import "contracts/modules/royalties/policies/MutableRoyaltyProportionPolicy.sol";

contract RoyaltyDistributorTest is Test {
    RoyaltyDistributor public royaltyDistributor;
    IPAccountRegistry public registry;
    MockIPAccount public implementation;
    RoyaltyNFT public royaltyNft;
    ISplitMain public splitMain;
    MutableRoyaltyProportionPolicy public mutablePolicy;

    uint256 chainId;
    address tokenAddress;
    uint256 tokenId;

    struct ProportionData {
        address[] accounts;
        uint32[] percentAllocations;
    }

//    error IpAccountInitializationFailed();

    function setUp() public {
        implementation = new MockIPAccount();
        registry = new IPAccountRegistry(address(implementation));
        chainId = 100;
        tokenAddress = address(200);
        tokenId = 300;
        splitMain = new MockSplitMain();
        royaltyNft = new RoyaltyNFT(address(splitMain));
        royaltyDistributor = new RoyaltyDistributor(address(registry), address(royaltyNft));
        mutablePolicy = new MutableRoyaltyProportionPolicy(address(royaltyNft));
    }

    function test_setRoyaltyPolicy() public {
        royaltyDistributor.setRoyaltyPolicy(tokenAddress, tokenId, address(mutablePolicy), "");
        address configuredPolicy = royaltyDistributor.getRoyaltyPolicy(tokenAddress, tokenId);
        assertEq(address(mutablePolicy), configuredPolicy);
    }

    function test_updateDistribution() public {
        royaltyDistributor.setRoyaltyPolicy(tokenAddress, tokenId, address(mutablePolicy), "");
        address configuredPolicy = royaltyDistributor.getRoyaltyPolicy(tokenAddress, tokenId);
        assertEq(address(mutablePolicy), configuredPolicy);
        address tokenAccount = registry.account(
            block.chainid,
            tokenAddress,
            tokenId
        );
        uint32 tokenAlloc = 500000;
        address acc1 = address(300);
        uint32 alloc1 = 250000;
        address acc2 = address(400);
        uint32 alloc2 = 250000;

        address[] memory accounts = new address[](3);
        uint32[] memory percentAllocations = new uint32[](3);

        accounts[0] = tokenAccount;
        percentAllocations[0] = tokenAlloc;
        accounts[1] = acc1;
        percentAllocations[1] = alloc1;
        accounts[2] = acc2;
        percentAllocations[2] = alloc2;

        ProportionData memory data = ProportionData({
            accounts: accounts,
            percentAllocations: percentAllocations
        });

        royaltyDistributor.updateDistribution(tokenAddress, tokenId, abi.encode(data));

        assertEq(royaltyNft.balanceOf(tokenAccount, royaltyNft.toTokenId(tokenAccount)), 500000);

    }
}
