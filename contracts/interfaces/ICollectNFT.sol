// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ICollectNFTEventsAndErrors } from "./ICollectNFTEventsAndErrors.sol";
import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";

/// @title Collect NFT Interface
/// @notice Contracts implementing the Collect NFT interface may be collected
///         through a collect module for a bound franchise IP asset.
interface ICollectNFT is IERC721, ICollectNFTEventsAndErrors {
    /// @notice Returns the total # of collect NFTs that exist for an IP asset.
    /// @return The total number of collect NFTs in the collection.
    function totalSupply() external view returns (uint256);

    /// @notice Initializes a collect NFT for subsequent collection.
    /// @param initParams Collect NFT init data, including bound franchise IP
    ///        asset registry, IP asset id, and generic unformatted init data.
    function initialize(InitCollectNFTParams calldata initParams) external;

    /// @notice Performs a collect, minting the NFT to address `collector`.
    /// @param collector The address of the target designated for collection.
    /// @param data Additional unformatted bytes data for optional processing.
    /// @return tokenId The id of the minted collect NFT.
    function collect(
        address collector,
        bytes calldata data
    ) external returns (uint256);
}
