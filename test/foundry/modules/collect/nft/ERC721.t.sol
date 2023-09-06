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

    function testSupportsInterface() public {
        _testSupportsInterface(erc721);
    }
    function testERC721ApprovalOwner(uint256 tokenId, address owner, address operator, address approved) public mintTokenForOwner(owner, tokenId) {
        _testERC721ApprovalOwner(erc721, tokenId, owner, approved);
    }

    function testERC721ApprovalOperator(uint256 tokenId, address owner, address operator, address approved) public mintTokenForOwner(owner, tokenId) {
        _testERC721ApprovalOperator(erc721, tokenId, owner, operator, approved);
    }

    function testERC721ApprovalNonOwnerReverts(uint256 tokenId, address owner, address operator, address approved) public mintTokenForOwner(owner, tokenId) {
        _testERC721ApprovalNonOwnerReverts(erc721, tokenId, owner, operator, approved);
    }

    function testERC721SafeTransferReceive(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _testERC721SafeTransferReceive,
            erc721,
            tokenId,
            owner,
            sender
        );
    }

    function testERC721SafeTransferInvalidReceiverReverts(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _testERC721SafeTransferInvalidReceiverReverts,
            erc721,
            tokenId,
            owner,
            sender
        );
    }

    function testERC721SafeTransferThrowingReceiverReverts(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _testERC721SafeTransferThrowingReceiverReverts,
            erc721,
            tokenId,
            owner,
            sender
        );

    }

    function testERC721SafeTransferInvalidMagicValueReverts(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _testERC721SafeTransferInvalidMagicValueReverts,
            erc721,
            tokenId,
            owner,
            sender
        );

    }

    function testERC721TransferFromOperator(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _testERC721TransferFromOperator,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function testERC721TransferFromApproved(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _testERC721TransferFromApproved,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function testERC721TransferFromOwner(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, 0) {
        _runAllTransferTestVariants(
            _testERC721TransferFromOwner,
            erc721,
            0,
            owner,
            sender,
            receiver
        );
    }

    function testERC721TransferToZeroAddressReverts(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _testERC721TransferToZeroAddressReverts,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function testERC721TransferFromUnauthorizedSenderReverts(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _testERC721TransferUnauthorizedSenderReverts,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function testERC721TransferFromNonOwnerReverts(uint256 tokenId, address owner, address sender, address receiver) public mintTokenForOwner(owner, tokenId) {
        _runAllTransferTestVariants(
            _testERC721TransferFromNonOwnerReverts,
            erc721,
            tokenId,
            owner,
            sender,
            receiver
        );
    }

    function testERC721Mint(uint256 tokenId, address owner) public {

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

    function testERC721MintZeroAddressReverts(uint256 tokenId) public {
        vm.expectRevert(ERC721ReceiverInvalid.selector);
        erc721.mint(address(0), tokenId);
    }

    function testERC721MintDuplicateReverts(uint256 tokenId, address owner) public {
        vm.assume(owner != address(0));
        erc721.mint(owner, tokenId);
        vm.expectRevert(ERC721TokenAlreadyMinted.selector);
        erc721.mint(owner, tokenId);
    }

    function testERC721Burn(uint256 tokenId, address owner) public mintTokenForOwner(owner, tokenId) {

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

    function testERC721BurnClearsApproval(uint256 tokenId, address owner) public mintTokenForOwner(owner, tokenId) {
        vm.prank(owner);
        erc721.approve(alice, tokenId);
        assertEq(erc721.getApproved(tokenId), alice);
        erc721.burn(tokenId);
        assertEq(erc721.getApproved(tokenId), address(0));
    }

    function testERC721BurnDuplicateReverts(uint256 tokenId, address owner) public mintTokenForOwner(owner, tokenId) {
        erc721.burn(tokenId);
        vm.expectRevert(ERC721TokenNonExistent.selector);
        erc721.burn(tokenId);
    }

    function testERC721BurnNonexistentTokenReverts(uint256 tokenId) public {
        vm.expectRevert(ERC721TokenNonExistent.selector);
        erc721.burn(tokenId);
    }

}
