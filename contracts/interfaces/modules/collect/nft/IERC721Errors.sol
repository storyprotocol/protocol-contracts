// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// @title ERC-721 Errors Interface
interface IERC721Errors {
    /// @notice Originating address does not own the NFT.
    error ERC721OwnerInvalid();

    /// @notice Receiving address cannot be the zero address.
    error ERC721ReceiverInvalid();

    /// @notice Receiving contract does not implement the ERC-721 wallet interface.
    error ERC721SafeTransferUnsupported();

    /// @notice Sender is not NFT owner, approved address, or owner operator.
    error ERC721SenderUnauthorized();

    /// @notice Token has already been minted.
    error ERC721TokenAlreadyMinted();

    /// @notice NFT does not exist.
    error ERC721TokenNonExistent();
}
