// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/ip-accounts/IPAccountRegistry.sol";
import "test/foundry/mocks/MockIPAccount.sol";
import "contracts/modules/royalties/RoyaltyDistributor.sol";
import "contracts/modules/royalties/RoyaltyNFT.sol";
import "contracts/modules/royalties/ISplitMain.sol";
import "./mocks/MockSplitMain.sol";
import "./mocks/MockERC20.sol";
import "test/foundry/mocks/MockSplitMain.sol";
import "contracts/modules/royalties/policies/MutableRoyaltyProportionPolicy.sol";

contract RoyaltyDistributorTest is Test {
    RoyaltyDistributor public royaltyDistributor;
    IPAccountRegistry public registry;
    MockIPAccount public implementation;
    RoyaltyNFT public royaltyNft;
    ISplitMain public splitMain;
    MutableRoyaltyProportionPolicy public mutablePolicy;
    MockERC20 public mERC20;

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
//        splitMain = ISplitMain(0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE);
        royaltyNft = new RoyaltyNFT(address(splitMain));
        royaltyDistributor = new RoyaltyDistributor(address(registry), address(royaltyNft));
        mutablePolicy = new MutableRoyaltyProportionPolicy(address(royaltyNft));
        mERC20 = new MockERC20("Royalty Token", "RTK", 18);
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

    function test_distribute() public {
        // setup distribution
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

        // mint ERC20

        // transfer the ERC 20 to ip accounts
        // distribute
        // claim the ERC 20
        // verify balance is good

        mERC20.mint(10000);
        mERC20.transfer(tokenAccount, 10000);
        assertEq(mERC20.balanceOf(tokenAccount), 10000);
        vm.startPrank(tokenAccount);
        mERC20.approve(address(royaltyNft), 10000);
        vm.stopPrank();
        royaltyDistributor.distribute(tokenAddress, tokenId, address(mERC20));
        assertEq(splitMain.getERC20Balance(acc1, mERC20), 2500);

        assertEq(mERC20.balanceOf(acc1), 0);
        royaltyDistributor.claim(acc1, address(mERC20));
        assertEq(mERC20.balanceOf(acc1), 2500);
    }
}
