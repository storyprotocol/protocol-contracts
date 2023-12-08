// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/ip-accounts/IPAccountRegistry.sol";
import "contracts/ip-accounts/IPAccountImpl.sol";
import "contracts/interfaces/ip-accounts/IIPAccount.sol";
import "contracts/interfaces/ip-accounts/IERC6551Account.sol";
import { Errors } from "contracts/lib/Errors.sol";
import "test/foundry/mocks/MockERC721.sol";

contract IPAccountTest is Test {
    IPAccountRegistry public registry;
    IPAccountImpl public implementation;
    MockERC721 nft = new MockERC721();

    function setUp() public {
        implementation = new IPAccountImpl();
        registry = new IPAccountRegistry(address(implementation));
    }

    function test_Idempotency() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        address predictedAccount = registry.account(
            block.chainid,
            address(nft),
            tokenId
        );

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);

        address deployedAccount = registry.createAccount(
            block.chainid,
            address(nft),
            tokenId,
            ""
        );

        assertTrue(deployedAccount != address(0));

        assertEq(predictedAccount, deployedAccount);

        // Create account twice
        deployedAccount = registry.createAccount(
            block.chainid,
            address(nft),
            tokenId,
            ""
        );
        assertEq(predictedAccount, deployedAccount);
    }

    function test_TokenAndOwnership() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            block.chainid,
            address(nft),
            tokenId,
            ""
        );

        IIPAccount ipAccount = IIPAccount(payable(account));

        // Check token and owner functions
        (uint256 chainId_, address tokenAddress_, uint256 tokenId_) = ipAccount.token();
        assertEq(chainId_, block.chainid);
        assertEq(tokenAddress_, address(nft));
        assertEq(tokenId_, tokenId);
        assertEq(ipAccount.isValidSigner(owner, ""), IERC6551Account.isValidSigner.selector);

        // Transfer token to new owner and make sure account owner changes
        address newOwner = vm.addr(2);
        vm.prank(owner);
        nft.safeTransferFrom(owner, newOwner, tokenId);
        assertEq(
            ipAccount.isValidSigner(newOwner, ""),
            IERC6551Account.isValidSigner.selector
        );
    }

    function test_OwnershipOnlyControl() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            block.chainid,
            address(nft),
            tokenId,
            ""
        );

        uint256 subTokenId = 111;
        nft.mint(account, subTokenId);

        IIPAccount ipAccount = IIPAccount(payable(account));

        address otherOwner = vm.addr(2);

        vm.prank(vm.addr(3));
        vm.expectRevert(Errors.IPAccountImpl_CallerNotOwner.selector);
        ipAccount.safeTransferFrom(address(nft), account, otherOwner, subTokenId);

        vm.prank(owner);
        ipAccount.safeTransferFrom(address(nft), account, otherOwner, subTokenId);

        assertEq(nft.ownerOf(subTokenId),  otherOwner);
        assertEq(ipAccount.state(), 1);
    }


    function test_ERC721Receive() public {
        address owner = vm.addr(1);
        uint256 tokenId = 100;

        nft.mint(owner, tokenId);

        vm.prank(owner, owner);
        address account = registry.createAccount(
            block.chainid,
            address(nft),
            tokenId,
            ""
        );

        address otherOwner = vm.addr(2);
        uint256 otherTokenId = 200;
        nft.mint(otherOwner, otherTokenId);
        vm.prank(otherOwner);
        nft.safeTransferFrom(otherOwner, account, otherTokenId);
        assertEq(nft.balanceOf(account), 1);
        assertEq(nft.ownerOf(otherTokenId), account);
    }
}
