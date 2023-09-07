// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721Errors } from "contracts/interfaces/IERC721Errors.sol";
import { IERC721Events } from "contracts/interfaces/IERC721Events.sol";
import { MockCollectModuleERC721 } from "test/foundry/mocks/MockCollectModuleERC721.sol";
import { BaseTestUtils } from "test/foundry/utils/BaseTestUtils.sol";
import { MockERC721Receiver } from "test/foundry/mocks/MockERC721Receiver.sol";

contract BaseERC721Test is IERC721Errors, IERC721Events, BaseTestUtils {

    bytes4 constant ERC721_RECEIVER_MAGIC_VALUE = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    enum TransferType { SAFE_TRANSFER_WITH_DATA, SAFE_TRANSFER_WITHOUT_DATA, TRANSFER }

    bytes private SAFE_TRANSFER_DATA = "mockERC721SafeTransferFromData";
    
    function setUp() public virtual override(BaseTestUtils) {
        super.setUp();
    }

    function _test_ERC721ApprovalOwner(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address approved
    ) internal stateless {
        assertTrue(erc721.getApproved(tokenId) == address(0));
        vm.prank(owner);
        vm.expectEmit(address(erc721));
        emit Approval(owner, approved, tokenId);
        erc721.approve(approved, tokenId);
        assertEq(erc721.getApproved(tokenId), approved);
    }

    function _test_ERC721ApprovalOperator(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address operator,
        address approved
    ) internal stateless {
        assertTrue(erc721.getApproved(tokenId) == address(0));
        assertFalse(erc721.isApprovedForAll(owner, operator));
        vm.prank(owner);
        vm.expectEmit(address(erc721));
        emit ApprovalForAll(owner, operator, true);
        erc721.setApprovalForAll(operator, true);
        assertTrue(erc721.isApprovedForAll(owner, operator));
        vm.prank(operator);
        vm.expectEmit(address(erc721));
        emit Approval(owner, approved, tokenId);
        erc721.approve(approved, tokenId);
        assertEq(erc721.getApproved(tokenId), approved);
    }

    function _test_ERC721ApprovalNonOwnerReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address operator,
        address approved
    ) internal stateless {
        vm.assume(operator != owner);
        vm.prank(operator);
        vm.expectRevert(ERC721SenderUnauthorized.selector);
        erc721.approve(approved, tokenId);
    }


    // Transfer Test Suite
    function _test_ERC721TransferFromOperator(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver,
        TransferType transferType
    ) internal stateless {
        vm.assume(receiver != address(0));
        vm.prank(owner);
        erc721.setApprovalForAll(sender, true);
        assertTrue(erc721.isApprovedForAll(owner, sender));
        _test_ERC721TransferSuccess(erc721, tokenId,  owner, sender, receiver, transferType);
    }

    function _test_ERC721TransferFromApproved(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver,
        TransferType transferType
    ) internal stateless {
        vm.assume(receiver != address(0));
        vm.prank(owner);
        erc721.approve(sender, tokenId);
        _test_ERC721TransferSuccess(erc721, tokenId,  owner, sender, receiver, transferType);
    }

    function _test_ERC721TransferFromOwner(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address,
        address receiver,
        TransferType transferType
    ) internal stateless {
        vm.assume(receiver != address(0));
        _test_ERC721TransferSuccess(erc721, tokenId, owner, owner, receiver, transferType);
    }

    function _test_ERC721TransferToZeroAddressReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address,
        address,
        TransferType transferType
    ) internal stateless {
        vm.expectRevert(ERC721ReceiverInvalid.selector);
        _transfer(transferType, erc721, owner, owner, address(0), tokenId);
    }

    function _test_ERC721TransferFromNonOwnerReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver,
        TransferType transferType
    ) internal stateless {
        vm.assume(owner != sender);
        vm.expectRevert(ERC721OwnerInvalid.selector);
        _transfer(transferType, erc721, sender, sender, receiver, tokenId);
    }

    function _test_ERC721TransferUnauthorizedSenderReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver,
        TransferType transferType
    ) internal stateless {
        vm.assume(sender != owner);
        vm.assume(sender != address(0));
        vm.expectRevert(ERC721SenderUnauthorized.selector);
        _transfer(transferType, erc721, sender, owner, receiver, tokenId);
    }

    function _test_ERC721SafeTransferInvalidMagicValueReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address,
        TransferType transferType
    ) internal stateless {
        MockERC721Receiver invalidReceiver = new MockERC721Receiver(0xDEADBEEF, false);
        vm.expectRevert(ERC721SafeTransferUnsupported.selector);
        _transfer(transferType, erc721, owner, owner, address(invalidReceiver), tokenId);
    }

    function _test_ERC721SafeTransferThrowingReceiverReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address,
        TransferType transferType
    ) internal stateless {
        MockERC721Receiver invalidReceiver = new MockERC721Receiver(ERC721_RECEIVER_MAGIC_VALUE, true);
        vm.expectRevert(ERC721SafeTransferUnsupported.selector);
        _transfer(transferType, erc721, owner, owner, address(invalidReceiver), tokenId);
    }

    function _test_ERC721SafeTransferReceive(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address,
        TransferType transferType
    ) internal stateless {
        MockERC721Receiver validReceiver = new MockERC721Receiver(IERC721Receiver.onERC721Received.selector, false);
        bytes memory data = (transferType == TransferType.SAFE_TRANSFER_WITH_DATA) ? SAFE_TRANSFER_DATA : bytes("");
        vm.expectEmit(address(validReceiver));
        emit ERC721Received(owner, owner, tokenId, data);
        _transfer(transferType, erc721, owner, owner, address(validReceiver), tokenId);
    }

    function _test_ERC721SafeTransferInvalidReceiverReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address,
        TransferType transferType
    ) internal stateless {
        vm.expectRevert();
        _transfer(transferType, erc721, owner, owner, address(this), tokenId);
    }

    function _runAllTransferTestVariants(
        function(IERC721, uint256, address, address, address, TransferType) internal test_TransferVariant,
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver
    ) internal isValidReceiver(receiver) {
        test_TransferVariant(erc721, tokenId, owner, sender, receiver, TransferType.TRANSFER);
        test_TransferVariant(erc721, tokenId, owner, sender, receiver, TransferType.SAFE_TRANSFER_WITHOUT_DATA);
        test_TransferVariant(erc721, tokenId, owner, sender, receiver, TransferType.SAFE_TRANSFER_WITH_DATA);
    }

    function _runAllSafeTransferTestVariants(
        function(IERC721, uint256, address, address, TransferType) internal test_SafeTransferVariant,
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender
    ) internal {
        test_SafeTransferVariant(erc721, tokenId, owner, sender, TransferType.SAFE_TRANSFER_WITHOUT_DATA);
        test_SafeTransferVariant(erc721, tokenId, owner, sender, TransferType.SAFE_TRANSFER_WITH_DATA);
    }

    function _test_ERC721TransferSuccess(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver,
        TransferType transferType
    ) private {
        uint256 ownerBalance = erc721.balanceOf(owner);
        uint256 receiverBalance = erc721.balanceOf(receiver);
        vm.expectEmit(address(erc721));
        emit Transfer(owner, receiver, tokenId);
        _transfer(transferType, erc721, sender, owner, receiver, tokenId);
        assertEq(erc721.ownerOf(tokenId), receiver);
        if (owner == receiver) {
            assertEq(erc721.balanceOf(owner), ownerBalance);
        } else {
            assertEq(erc721.balanceOf(owner), ownerBalance - 1);
            assertEq(erc721.balanceOf(receiver), receiverBalance + 1);
        }
    }

    function _test_ERC721SupportsInterface(IERC721 erc721) internal {
        assertTrue(erc721.supportsInterface(0x01ffc9a7)); // ERC-165
        assertTrue(erc721.supportsInterface(0x80ac58cd)); // ERC-721
    }
    
    function _transfer(
        TransferType transferType,
        IERC721 erc721,
        address sender,
        address from,
        address to,
        uint256 tokenId
    ) private {
        vm.prank(sender);
        if (transferType == TransferType.SAFE_TRANSFER_WITH_DATA) {
            erc721.safeTransferFrom(from, to, tokenId, SAFE_TRANSFER_DATA);
        } else if (transferType == TransferType.SAFE_TRANSFER_WITHOUT_DATA) {
            erc721.safeTransferFrom(from, to, tokenId);
        } else if (transferType == TransferType.TRANSFER) {
            erc721.transferFrom(from, to, tokenId);
        }
    }

}
