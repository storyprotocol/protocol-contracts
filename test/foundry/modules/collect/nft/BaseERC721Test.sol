// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721Errors } from "contracts/interfaces/IERC721Errors.sol";
import { IERC721Events } from "contracts/interfaces/IERC721Events.sol";
import { MockCollectModuleERC721 } from "test/foundry/mocks/MockCollectModuleERC721.sol";
import { MockERC721Receiver } from "test/foundry/mocks/MockERC721Receiver.sol";

contract BaseERC721Test is IERC721Errors, IERC721Events, Test {

    bytes4 constant ERC721_RECEIVER_MAGIC_VALUE = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));

    uint256 internal alicePk = 0xa11ce;
    uint256 internal bobPk = 0xb0b;
    uint256 internal calPk = 0xca1;

    address payable internal alice = payable(vm.addr(alicePk));
    address payable internal bob = payable(vm.addr(bobPk));
    address payable internal cal = payable(vm.addr(calPk));

    enum TransferType { SAFE_TRANSFER_WITH_DATA, SAFE_TRANSFER_WITHOUT_DATA, TRANSFER }

    bytes private SAFE_TRANSFER_DATA = "mockERC721SafeTransferFromData";
    
    // https://github.com/foundry-rs/foundry/issues/2946
    modifier isValidReceiver(address receiver) {
        vm.assume(receiver != 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D); // HEVM Address
        vm.assume(receiver != 0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496); // Foundry Test Contract
        vm.assume(receiver != 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f);
        vm.assume(receiver != 0x4e59b44847b379578588920cA78FbF26c0B4956C); // CREATE2 Deployer
        _;
    }

    modifier stateless() {
        uint256 snapshot = vm.snapshot();
        _;
        vm.revertTo(snapshot);
    }

    function setUp() public virtual {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(cal, "cal");
    }

    function _testERC721ApprovalOwner(
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

    function _testERC721ApprovalOperator(
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

    function _testERC721ApprovalNonOwnerReverts(
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
    function _testERC721TransferFromOperator(
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
        _testERC721TransferSuccess(erc721, tokenId,  owner, sender, receiver, transferType);
    }

    function _testERC721TransferFromApproved(
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
        _testERC721TransferSuccess(erc721, tokenId,  owner, sender, receiver, transferType);
    }

    function _testERC721TransferFromOwner(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver,
        TransferType transferType
    ) internal stateless {
        vm.assume(receiver != address(0));
        console.log('wtf');
        _testERC721TransferSuccess(erc721, tokenId, owner, owner, receiver, transferType);
    }

    function _testERC721TransferToZeroAddressReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver,
        TransferType transferType
    ) internal stateless {
        vm.expectRevert(ERC721ReceiverInvalid.selector);
        _transfer(transferType, erc721, owner, owner, address(0), tokenId);
    }

    function _testERC721TransferFromNonOwnerReverts(
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

    function _testERC721TransferUnauthorizedSenderReverts(
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

    function _testERC721SafeTransferInvalidMagicValueReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        TransferType transferType
    ) internal stateless {
        MockERC721Receiver invalidReceiver = new MockERC721Receiver(0xDEADBEEF, false);
        vm.expectRevert(ERC721SafeTransferUnsupported.selector);
        _transfer(transferType, erc721, owner, owner, address(invalidReceiver), tokenId);
    }

    function _testERC721SafeTransferThrowingReceiverReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        TransferType transferType
    ) internal stateless {
        MockERC721Receiver invalidReceiver = new MockERC721Receiver(ERC721_RECEIVER_MAGIC_VALUE, true);
        vm.expectRevert(ERC721SafeTransferUnsupported.selector);
        _transfer(transferType, erc721, owner, owner, address(invalidReceiver), tokenId);
    }

    function _testERC721SafeTransferReceive(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        TransferType transferType
    ) internal stateless {
        MockERC721Receiver validReceiver = new MockERC721Receiver(IERC721Receiver.onERC721Received.selector, false);
        bytes memory data = (transferType == TransferType.SAFE_TRANSFER_WITH_DATA) ? SAFE_TRANSFER_DATA : bytes("");
        vm.expectEmit(address(validReceiver));
        emit ERC721Received(owner, owner, tokenId, data);
        _transfer(transferType, erc721, owner, owner, address(validReceiver), tokenId);
    }

    function _testERC721SafeTransferInvalidReceiverReverts(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        TransferType transferType
    ) internal stateless {
        vm.expectRevert();
        _transfer(transferType, erc721, owner, owner, address(this), tokenId);
    }

    function _runAllTransferTestVariants(
        function(IERC721, uint256, address, address, address, TransferType) internal testTransferVariant,
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver
    ) internal isValidReceiver(receiver) {
        testTransferVariant(erc721, tokenId, owner, sender, receiver, TransferType.TRANSFER);
        testTransferVariant(erc721, tokenId, owner, sender, receiver, TransferType.SAFE_TRANSFER_WITHOUT_DATA);
        testTransferVariant(erc721, tokenId, owner, sender, receiver, TransferType.SAFE_TRANSFER_WITH_DATA);
    }

    function _runAllSafeTransferTestVariants(
        function(IERC721, uint256, address, address, TransferType) internal testSafeTransferVariant,
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender
    ) internal {
        testSafeTransferVariant(erc721, tokenId, owner, sender, TransferType.SAFE_TRANSFER_WITHOUT_DATA);
        testSafeTransferVariant(erc721, tokenId, owner, sender, TransferType.SAFE_TRANSFER_WITH_DATA);
    }

    function _testERC721TransferSuccess(
        IERC721 erc721,
        uint256 tokenId,
        address owner,
        address sender,
        address receiver,
        TransferType transferType
    ) private {
        uint256 ownerBalance = erc721.balanceOf(owner);
        console.log(ownerBalance);
        uint256 receiverBalance = erc721.balanceOf(receiver);
        console.log(receiverBalance);
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

    function _testSupportsInterface(IERC721 erc721) internal {
        assertTrue(erc721.supportsInterface(0x01ffc9a7)); // ERC-165
        assertTrue(erc721.supportsInterface(0x80ac58cd));
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
