// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// @title Collect Module Events & Errors Interface
interface ICollectModuleEventsAndErrors {

    /// @notice Collect module caller is unauthorized.
    error CollectModuleCallerUnauthorized();

    /// @notice Collect NFT has already been initialized.
    error CollectModuleCollectNotYetInitialized();

    /// @notice Collect action is not authorized for the collect module.
    error CollectModuleCollectUnauthorized();

    /// @notice Collect module IP asset is already initialized.
    error CollectModuleIPAssetAlreadyInitialized();

    /// @notice Collect module IP asset does not exist.
    error CollectModuleIPAssetNonExistent();

    /// @notice Collect module provided IP asset registry does not exist.
    error CollectModuleIPAssetRegistryNonExistent();

}
