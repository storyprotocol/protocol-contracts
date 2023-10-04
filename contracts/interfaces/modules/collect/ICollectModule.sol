// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { InitCollectParams, CollectParams } from "contracts/lib/CollectModuleStructs.sol";
import { ICollectModuleEventsAndErrors } from "./ICollectModuleEventsAndErrors.sol";

/// @title Collect Module Interface
/// @notice The collect module enables IP assets to be minted as NFTs mirroring
///         their binding IP assets in a franchise-configurable format.
interface ICollectModule is ICollectModuleEventsAndErrors {
    /// @notice Initializes the collect module for a specific IP asset.
    /// @param initCollectParams Collect module init data, including IP asset
    ///        id, collect NFT impl address, and generic unformatted init data.
    function initCollect(InitCollectParams calldata initCollectParams) external;

    /// @notice Performs a collect on a specific IP asset for a collector.
    /// @param collectParams Collect module collect data, including IP asset id,
    ///         collector address, and generic unformatted collect and NFT data.
    /// @return collectNFT The address of the collected NFT.
    /// @return collectNFTId The id of the collected collect NFT.
    function collect(
        CollectParams calldata collectParams
    ) external payable returns (address collectNFT, uint256 collectNFTId);

    /// @notice Returns the collect NFT address associated with an IP asset.
    /// @param  franchiseId The id of the franchise of the specified IP asset.
    /// @param  ipAssetId The id of the specified IP asset within the franchise.
    /// @return The Collect NFT address if it exists, else the zero address.
    function getCollectNFT(
        uint256 franchiseId,
        uint256 ipAssetId
    ) external returns (address);
}
