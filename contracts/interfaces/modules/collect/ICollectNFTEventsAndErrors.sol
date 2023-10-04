// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ICollectNFTEventsAndErrors {
    /// @notice Collect NFT has already been initialized.
    error CollectNFTAlreadyInitialized();

    /// @notice Caller of the Collect NFT is not authorized.
    error CollectNFTCallerUnauthorized();

    /// @notice Collector address is not valid.
    error CollectNFTCollectorInvalid();

    /// @notice IP asset bound to the Collect NFT does not exist.
    error CollectNFTIPAssetNonExistent();
}
