// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// @notice Parameters passed to initialize a collect NFT.
struct InitCollectNFTParams {
    address ipAssetRegistry; // Address of the registry of the bound IP asset.
    uint256 ipAssetId;       // The id of the IP asset bound to the collect NFT.
    bytes data;              // Additional data used for NFT initialization.
}
