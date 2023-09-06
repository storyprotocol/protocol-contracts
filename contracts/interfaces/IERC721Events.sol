// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// @title ERC-721 Events Interface
interface IERC721Events {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event ERC721Received(address operator, address from, uint256 tokenId, bytes data);

}
