// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { BaseERC721Test } from "./BaseERC721Test.sol";
import { MockCollectModuleERC721 } from "test/foundry/mocks/MockCollectModuleERC721.sol";

contract ERC721Test is BaseERC721Test {

    MockCollectModuleERC721 erc721;

    modifier mintTokenForOwner(address owner, uint256 tokenId) {
        vm.assume(owner != address(0));
        erc721.mint(owner, tokenId);
        assertEq(erc721.ownerOf(tokenId), owner);
        _;
    }

    function setUp() public virtual override { 
        super.setUp();
        erc721 = new MockCollectModuleERC721();
        vm.label(address(erc721), "MockCollectModuleERC721");
    }

    function test_ERC721SupportsInterface() public {
        _test_ERC721SupportsInterface(erc721);
    }

    function test_ERC721ApprovalOwner(uint256 tokenId, address owner, address approved) public mintTokenForOwner(owner, tokenId) {
        _test_ERC721ApprovalOwner(erc721, tokenId, owner, approved);
    }

    function test_ERC721ApprovalOperator(uint256 tokenId, address owner, address operator, address approved) public mintTokenForOwner(owner, tokenId) {
        _test_ERC721ApprovalOperator(erc721, tokenId, owner, operator, approved);
    }

    function test_ERC721ApprovalNonOwnerReverts(uint256 tokenId, address owner, address operator, address approved) public mintTokenForOwner(owner, tokenId) {
        _test_ERC721ApprovalNonOwnerReverts(erc721, tokenId, owner, operator, approved);
    }

    function test_ERC721SafeTransferReceive(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _test_ERC721SafeTransferReceive,
            erc721,
            tokenId,
            owner,
            sender
        );
    }

    function test_ERC721SafeTransferInvalidReceiverReverts(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _test_ERC721SafeTransferInvalidReceiverReverts,
            erc721,
            tokenId,
            owner,
            sender
        );
    }

    function test_ERC721SafeTransferThrowingReceiverReverts(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _test_ERC721SafeTransferThrowingReceiverReverts,
            erc721,
            tokenId,
            owner,
            sender
        );

    }

    function test_ERC721SafeTransferInvalidMagicValueReverts(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _test_ERC721SafeTransferInvalidMagicValueReverts,
            erc721,
            tokenId,
            owner,
            sender
        );

    }

    function test_ERC721TransferFromOperator(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _test_ERC721TransferFromOperator,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function test_ERC721TransferFromApproved(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _test_ERC721TransferFromApproved,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function test_ERC721TransferFromOwner(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _test_ERC721TransferFromOwner,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function test_ERC721TransferToZeroAddressReverts(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _test_ERC721TransferToZeroAddressReverts,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function test_ERC721TransferFromUnauthorizedSenderReverts(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _test_ERC721TransferUnauthorizedSenderReverts,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function test_ERC721TransferFromNonOwnerReverts(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _test_ERC721TransferFromNonOwnerReverts,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function test_ERC721Mint(uint256 tokenId, address owner) public {

        vm.assume(owner != address(0));
        uint256 totalSupply = erc721.totalSupply();
        uint256 balance = erc721.balanceOf(owner);
        assertEq(erc721.ownerOf(tokenId), address(0));

        vm.expectEmit(address(erc721));
        emit Transfer(address(0), owner, tokenId);
        erc721.mint(owner, tokenId);

        assertEq(erc721.balanceOf(owner), balance + 1);
        assertEq(erc721.totalSupply(), totalSupply + 1);
        assertEq(erc721.ownerOf(tokenId), owner);
    }

    function test_ERC721MintZeroAddressReverts(uint256 tokenId) public {
        vm.expectRevert(ERC721ReceiverInvalid.selector);
        erc721.mint(address(0), tokenId);
    }

    function test_ERC721MintDuplicateReverts(uint256 tokenId, address owner) public {
        vm.assume(owner != address(0));
        erc721.mint(owner, tokenId);
        vm.expectRevert(ERC721TokenAlreadyMinted.selector);
        erc721.mint(owner, tokenId);
    }

    function test_ERC721Burn(uint256 tokenId, address owner) public mintTokenForOwner(owner, tokenId) {

        uint256 totalSupply = erc721.totalSupply();
        uint256 balance = erc721.balanceOf(owner);
        assertEq(erc721.ownerOf(tokenId), owner);

        vm.expectEmit(address(erc721));
        emit Transfer(owner, address(0), tokenId);
        erc721.burn(tokenId);

        assertEq(erc721.totalSupply(), totalSupply - 1);
        assertEq(erc721.balanceOf(owner), balance - 1);
        assertEq(erc721.ownerOf(tokenId), address(0));
    }

    function test_ERC721BurnClearsApproval(uint256 tokenId, address owner) public mintTokenForOwner(owner, tokenId) {
        vm.prank(owner);
        erc721.approve(alice, tokenId);
        assertEq(erc721.getApproved(tokenId), alice);
        erc721.burn(tokenId);
        assertEq(erc721.getApproved(tokenId), address(0));
    }

    function test_ERC721BurnDuplicateReverts(uint256 tokenId, address owner) public mintTokenForOwner(owner, tokenId) {
        erc721.burn(tokenId);
        vm.expectRevert(ERC721TokenNonExistent.selector);
        erc721.burn(tokenId);
    }

    function test_ERC721BurnNonexistentTokenReverts(uint256 tokenId) public {
        vm.expectRevert(ERC721TokenNonExistent.selector);
        erc721.burn(tokenId);
    }

}
