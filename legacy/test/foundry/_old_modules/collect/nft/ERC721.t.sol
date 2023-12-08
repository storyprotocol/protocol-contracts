// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { BaseERC721Test } from "./BaseERC721Test.sol";
import { MockCollectModuleERC721 } from "mvp/test/foundry/mocks/MockCollectModuleERC721.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title ERC-721 Testing Contract
/// @notice Tests all ERC-721 functionality.
contract ERC721Test is BaseERC721Test {

    // Mock (overridable) ERC-721 used for testing.
    MockCollectModuleERC721 erc721;

    /// @notice Modifier that mints NFT `tokenId` for address `owner`.
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

    /// @notice Tests that the ERC-721 supports required interfaces.
    function test_ERC721SupportsInterface() public {
        _test_ERC721SupportsInterface(erc721);
    }

    /// @notice Tests that ERC-721 owner approvals work.
    function test_ERC721ApprovalOwner(uint256 tokenId, address owner, address approved) public mintTokenForOwner(owner, tokenId) {
        _test_ERC721ApprovalOwner(erc721, tokenId, owner, approved);
    }

    /// @notice Tests that ERC-721 operator approvals work.
    function test_ERC721ApprovalOperator(uint256 tokenId, address owner, address operator, address approved) public mintTokenForOwner(owner, tokenId) {
        _test_ERC721ApprovalOperator(erc721, tokenId, owner, operator, approved);
    }

    /// @notice Tests that non-owner approvals throw.
    function test_ERC721ApprovalNonOwnerReverts(uint256 tokenId, address owner, address operator, address approved) public mintTokenForOwner(owner, tokenId) {
        _test_ERC721ApprovalNonOwnerReverts(erc721, tokenId, owner, operator, approved);
    }

    /// @notice Tests expected behavior of safe transfer receives.
    function test_ERC721SafeTransferReceive(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _test_ERC721SafeTransferReceive,
            erc721,
            tokenId,
            owner,
            sender
        );
    }

    /// @notice Tests that safe transfers to invalid receivers throw.
    function test_ERC721SafeTransferInvalidReceiverReverts(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _test_ERC721SafeTransferInvalidReceiverReverts,
            erc721,
            tokenId,
            owner,
            sender
        );
    }

    /// @notice Tests that safe transfers to reverting receivers throw.
    function test_ERC721SafeTransferThrowingReceiverReverts(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _test_ERC721SafeTransferThrowingReceiverReverts,
            erc721,
            tokenId,
            owner,
            sender
        );

    }

    /// @notice Tests that safe transfers to receivers returning invalid magic values throw.
    function test_ERC721SafeTransferInvalidMagicValueReverts(uint256 tokenId, address owner, address sender) public mintTokenForOwner(owner, tokenId) {
        _runAllSafeTransferTestVariants(
            _test_ERC721SafeTransferInvalidMagicValueReverts,
            erc721,
            tokenId,
            owner,
            sender
        );

    }

    /// @notice Tests that operator transfers work as expected.
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

    /// @notice Tests that transfers sent by the approved address succeed.
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

    /// @notice Tests that transfers sent by NFT owners succeed.
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

    /// @notice Tests that transfers to the zero address throw.
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

    /// @notice Tests that transfers from unauthorized senders throw.
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

    /// @notice Tests that transfers from non-owners throw.
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


    /// @notice Tests that mints succeed.
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

    /// @notice Tests that mints to the zero address throw.
    function test_ERC721MintZeroAddressReverts(uint256 tokenId) public {
        vm.expectRevert(Errors.ERC721_ReceiverInvalid.selector);
        erc721.mint(address(0), tokenId);
    }

    /// @notice Tests that duplicate mints throw.
    function test_ERC721MintDuplicateReverts(uint256 tokenId, address owner) public {
        vm.assume(owner != address(0));
        erc721.mint(owner, tokenId);
        vm.expectRevert(Errors.ERC721_TokenAlreadyMinted.selector);
        erc721.mint(owner, tokenId);
    }

    /// @notice Tests that burns work as expected.
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

    /// @notice Tests that burns clear all approvals.
    function test_ERC721BurnClearsApproval(uint256 tokenId, address owner) public mintTokenForOwner(owner, tokenId) {
        vm.prank(owner);
        erc721.approve(alice, tokenId);
        assertEq(erc721.getApproved(tokenId), alice);
        erc721.burn(tokenId);
        assertEq(erc721.getApproved(tokenId), address(0));
    }

    /// @notice Tests that duplicate burns revert.
    function test_ERC721BurnDuplicateReverts(uint256 tokenId, address owner) public mintTokenForOwner(owner, tokenId) {
        erc721.burn(tokenId);
        vm.expectRevert(Errors.ERC721_TokenNonExistent.selector);
        erc721.burn(tokenId);
    }

    /// @notice Tests that burns of non-existent tokens revert.
    function test_ERC721BurnNonexistentTokenReverts(uint256 tokenId) public {
        vm.expectRevert(Errors.ERC721_TokenNonExistent.selector);
        erc721.burn(tokenId);
    }

}
