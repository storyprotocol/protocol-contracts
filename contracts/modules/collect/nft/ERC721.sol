// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC721Errors } from "../../../interfaces/IERC721Errors.sol";

/// @title Minimal ERC-721 Contract
abstract contract ERC721 is IERC721, IERC721Errors {

    /// @notice The total number of ERC-721 NFTs in circulation.
    uint256 public _totalSupply;

    /// @notice Maps tokens to their owner addresses.
    mapping(uint256 => address) public ownerOf;

    /// @notice Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @notice Gets the approved address for an NFT.
    mapping(uint256 => address) public getApproved;

    /// @notice Gets the number of NFTs owned by an address.
    mapping(address => uint256) public balanceOf;

    /// @dev EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 private constant _ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    /// @notice Sets the operator for `msg.sender` to `operator`.
    /// @param operator The operator address managing NFTs of `msg.sender`.
    /// @param approved Whether operator can manage NFTs of `msg.sender`.
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Sets approved address of NFT of id `id` to address `approved`.
    /// @param approved The new approved address for the NFT.
    /// @param tokenId The id of the NFT to approve.
    function approve(address approved, uint256 tokenId) public virtual {
        address owner = ownerOf[tokenId];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
            revert ERC721SenderUnauthorized();
        }

        getApproved[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The new owner address of the NFT being transferred.
    /// @param data Additional data in bytes to pass to the receiver.
    /// @param tokenId The id of the NFT being transferred.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external {
        transferFrom(from, to, tokenId);
        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data)
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert ERC721SafeTransferUnsupported();
        }
    }
    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  with safety checks ensuring `to` is capable of receiving the NFT.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    /// @param from The existing owner address of the NFT to be transferred.
    /// @param to The new owner address of the NFT being transferred.
    /// @param tokenId The id of the NFT being transferred.
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        transferFrom(from, to, tokenId);
        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, "")
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert ERC721SafeTransferUnsupported();
        }
    }

    /// @notice Transfers NFT of id `id` from address `from` to address `to`,
    ///  without performing any safety checks.
    /// @dev Existence of an NFT is inferred by having a non-zero owner address.
    ///  Transfers clear owner approvals without `Approval` events emitted.
    /// @param from The existing owner address of the NFT being transferred.
    /// @param to The new owner address of the NFT being transferred.
    /// @param tokenId The id of the NFT being transferred.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        if (from != ownerOf[tokenId]) {
            revert ERC721OwnerInvalid();
        }

        if (
            msg.sender != from &&
            msg.sender != getApproved[tokenId] &&
            !isApprovedForAll[from][msg.sender]
        ) {
            revert ERC721SenderUnauthorized();
        }

        if (to == address(0)) {
            revert ERC721ReceiverInvalid();
        }

        delete getApproved[tokenId];

        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The ERC-165 interface identifier.
    /// @return True if interface id `id` is supported, false otherwise.
    function supportsInterface(bytes4 id) public view virtual override(IERC165) returns (bool) {
        return id == _ERC165_INTERFACE_ID ||
               id == _ERC721_INTERFACE_ID;
    }

    /// @notice Mints an NFT of identifier `tokenId` to recipient address `to`.
    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) {
            revert ERC721ReceiverInvalid();
        }

        if (ownerOf[tokenId] != address(0)) {
            revert ERC721TokenAlreadyMinted();
        }

        unchecked {
            _totalSupply++;
            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Burns an NFT with identifier `tokenId`.
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf[tokenId];

        if (owner == address(0)) {
            revert ERC721TokenNonExistent();
        }

        unchecked {
            _totalSupply--;
            balanceOf[owner]--;
        }

        delete ownerOf[tokenId];
        delete getApproved[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

}
