// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface ICollectModuleEventsAndErrors {

    /// @notice Collect action is not authorized.
    error CollectModuleCollectUnauthorized();

    /// @notice Collect module caller is unauthorized.
    error CollectModuleCallerUnauthorized();

    /// @notice Collect module IP asset is already initialized.
    error CollectModuleIPAssetAlreadyInitialized();

    /// @notice Collect module provided IP asset registry does not exist.
    error CollectModuleIPAssetRegistryNonExistent();

    /// @notice Collect NFT has already been initialized.
    error CollectModuleCollectNotYetInitialized();

    /// @notice Collect module IP asset does not exist.
    error CollectModuleIPAssetNonExistent();

}
