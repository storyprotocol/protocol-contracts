// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Collect } from "contracts/lib/modules/Collect.sol";

/// @title Collect NFT Interface
/// @notice Contracts implementing the Collect NFT interface may be collected
///         through a collect module for a bound IP asset collection.
interface ICollectNFT is IERC721 {
    /// @notice Initializes a collect NFT for subsequent collection.
    /// @param initParams_ Collect NFT init data, including bound franchise IP
    ///        asset registry, IP asset id, and generic unformatted init data.
    function initialize(Collect.InitCollectNFTParams calldata initParams_) external;

    /// @notice Performs a collect, minting the NFT to address `collector`.
    /// @param collector_ The address of the target designated for collection.
    /// @param data_ Additional unformatted bytes data for optional processing.
    /// @return tokenId_ The id of the minted collect NFT.
    function collect(
        address collector_,
        bytes calldata data_
    ) external returns (uint256);

    /// @notice Returns the total # of collect NFTs that exist for an IP asset.
    /// @return The total number of collect NFTs in the collection.
    function totalSupply() external view returns (uint256);
}
