// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Minimal Collect Module ERC-721 Contract
/// @notice This is a barebones ERC-721 contract that does not implement the
///         ERC-721 metadata standard. This contract is purposely lightweight
///         to support simpler standardization for collect NFTs, which:
///         - MAY mirror metadata from their bound IP assets, thus not
///           necessarily having the metadata defined in the collect NFT itself
///         - MUST support initialization via minimal clone proxies, thus not
///           requiring a constructor for IP asset specific intialization
///         - MAY not be upgradeable, thus not necessarily requiring a more
///           involved IERC721Upgradeable extension
abstract contract ERC721 is IERC721 {

    /// @notice Maps tokens to their owner addresses.
    mapping(uint256 => address) public ownerOf;

    /// @notice Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @notice Gets the approved address for an NFT.
    mapping(uint256 => address) public getApproved;

    /// @notice Gets the number of NFTs owned by an address.
    mapping(address => uint256) public balanceOf;

    // Tracks the total number of ERC-721 NFTs in circulation.
    uint256 public _totalSupply;

    // EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @notice Sets the operator for `msg.sender` to `operator`.
    /// @param operator_ The operator address managing NFTs of `msg.sender`.
    /// @param approved_ Whether operator can manage NFTs of `msg.sender`.
    function setApprovalForAll(address operator_, bool approved_) external {
        isApprovedForAll[msg.sender][operator_] = approved_;
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from_ The existing owner address of the NFT to be transferred.
    /// @param to_ The new owner address of the NFT being transferred.
    /// @param data_ Additional data in bytes to pass to the receiver.
    /// @param tokenId_ The id of the NFT being transferred.
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) external {
        transferFrom(from_, to_, tokenId_);
        if (
            to_.code.length != 0 &&
                IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_)
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert Errors.ERC721_SafeTransferUnsupported();
        }
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from_ The existing owner address of the NFT to be transferred.
    /// @param to_ The new owner address of the NFT being transferred.
    /// @param tokenId_ The id of the NFT being transferred.
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) external {
        transferFrom(from_, to_, tokenId_);
        if (
            to_.code.length != 0 &&
                IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, "")
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert Errors.ERC721_SafeTransferUnsupported();
        }
    }

    /// @notice Sets approved address of NFT `id` to address `approved`.
    /// @param approved_ The new approved address for the NFT.
    /// @param tokenId_ The id of the NFT to approve.
    function approve(address approved_, uint256 tokenId_) public virtual {
        address owner = ownerOf[tokenId_];

        // Revert unless msg.sender is the owner or approved operator.
        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
            revert Errors.ERC721_SenderUnauthorized();
        }

        getApproved[tokenId_] = approved_;
        emit Approval(owner, approved_, tokenId_);
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  without performing any safety checks.
    /// @dev Existence of an NFT is inferred by having a non-zero owner address.
    ///  Transfers clear owner approvals without `Approval` events emitted.
    /// @param from_ The existing owner address of the NFT being transferred.
    /// @param to_ The new owner address of the NFT being transferred.
    /// @param tokenId_ The id of the NFT being transferred.
    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        if (from_ != ownerOf[tokenId_]) {
            revert Errors.ERC721_OwnerInvalid();
        }

        if (
            msg.sender != from_ &&
            msg.sender != getApproved[tokenId_] &&
            !isApprovedForAll[from_][msg.sender]
        ) {
            revert Errors.ERC721_SenderUnauthorized();
        }

        if (to_ == address(0)) {
            revert Errors.ERC721_ReceiverInvalid();
        }

        delete getApproved[tokenId_];

        unchecked {
            balanceOf[from_]--;
            balanceOf[to_]++;
        }

        ownerOf[tokenId_] = to_;
        emit Transfer(from_, to_, tokenId_);
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id_ The ERC-165 interface identifier.
    /// @return True if interface id `id` is supported, false otherwise.
    function supportsInterface(bytes4 id_) public view virtual override(IERC165) returns (bool) {
        return id_ == _ERC165_INTERFACE_ID ||
               id_ == _ERC721_INTERFACE_ID;
    }

    /// @dev Mints an NFT of identifier `tokenId` to recipient address `to`.
    /// @param to_ Address of the new NFT owner.
    /// @param tokenId_ Id of the NFT being minted.
    function _mint(address to_, uint256 tokenId_) internal virtual {
        if (to_ == address(0)) {
            revert Errors.ERC721_ReceiverInvalid();
        }

        if (ownerOf[tokenId_] != address(0)) {
            revert Errors.ERC721_TokenAlreadyMinted();
        }

        unchecked {
            _totalSupply++;
            balanceOf[to_]++;
        }

        ownerOf[tokenId_] = to_;
        emit Transfer(address(0), to_, tokenId_);
    }

    /// @dev Burns an NFT with identifier `tokenId`.
    /// @param tokenId_ The id of the NFT being burned.
    function _burn(uint256 tokenId_) internal virtual {
        address owner = ownerOf[tokenId_];

        if (owner == address(0)) {
            revert Errors.ERC721_TokenNonExistent();
        }

        unchecked {
            _totalSupply--;
            balanceOf[owner]--;
        }

        delete ownerOf[tokenId_];
        delete getApproved[tokenId_];
        emit Transfer(owner, address(0), tokenId_);
    }
}
