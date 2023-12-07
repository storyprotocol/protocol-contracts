// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

/// @title ERC-721 Events Interface
interface IERC721Events {
    /// @notice Emits when `tokenId` is transferred from address `from` to `to`.
    /// @param from The address of the original NFT owner.
    /// @param to The address of the new NFT owner.
    /// @param tokenId The id of the NFT being transferred.
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /// @notice Emits when `owner` approves `approved` to operate on `tokenId`.
    /// @param owner The address of the current NFT owner.
    /// @param approved The address approved to operate on `tokenId`.
    /// @param tokenId The id of the NFT being approved.
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /// @notice Emits when `owner` approves `operator` to operate on their NFTs.
    /// @param owner The address of the current NFT owner.
    /// @param operator The address of the new NFT operator.
    /// @param approved Whether operator can operate on NFTs of owner.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}
