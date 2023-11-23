// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.18;

import { ERC721 } from "contracts/modules/collect/nft/ERC721.sol";

/// @title Mock Collect Module ERC721
/// @notice This mock ERC-721 is used for testing the minimal collect ERC-721.
contract MockCollectModuleERC721 is ERC721 {

    /// @notice Mints NFT `tokenId` to address `to`.
    /// @param to The address of the newly minted NFT owner.
    /// @param tokenId The id of the NFT being minted.
    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    /// @notice Burns NFT `tokenId`.
    /// @param tokenId The id of the NFT being burned.
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    /// @notice Returns the total supply of the NFT collection.
    /// @return The total number of NFTs in the collection.
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}
