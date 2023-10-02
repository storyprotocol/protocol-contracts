// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// @notice Parameters passed to initialize a collect module for an IP asset.
struct InitCollectParams {
    uint256 franchiseId; // The id of the franchise tied to the IP asset.
    uint256 ipAssetId; // The id of the IP asset under the franchise.
    address collectNFTImpl; // The address of the collect NFT impl to use.
    bytes data; // Additional data to be used for initialization.
}

/// @notice Parameters passed for collect processing for an IP asset.
struct CollectParams {
    uint256 franchiseId; // The id of the franchise tied to the IP asset.
    uint256 ipAssetId; // The id of the IP asset being collected.
    address collector; // The address designated for NFT collection.
    bytes collectData; // Additional data passed for module collection.
    bytes collectNFTInitData; // Additional data passed for NFT initialization.
    bytes collectNFTData; // Additional data passed for NFT collection.
}

/// @notice Collect module settings saved for a franchise IP asset.
/// @dev A zero address `collectNFTImpl` means to use a module default NFT impl.
struct CollectInfo {
    bool initialized; // Whether the collect module was initialized.
    address collectNFT; // The collect NFT that an IP asset is bound to.
    address collectNFTImpl; // The collect NFT impl address being used.
}
