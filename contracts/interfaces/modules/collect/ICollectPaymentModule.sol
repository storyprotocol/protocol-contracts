// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { ICollectModule } from "./ICollectModule.sol";
import { CollectPaymentInfo } from "contracts/lib/CollectPaymentModuleStructs.sol";
import { InitCollectParams, CollectParams } from "contracts/lib/CollectModuleStructs.sol";
import { ICollectPaymentModuleEventsAndErrors } from "./ICollectPaymentModuleEventsAndErrors.sol";

/// @title Collect Payment Module Interface
/// @notice The collect payment module enables IP assets to be bound to NFTs
///         that can be minted for a configurable fee.
interface ICollectPaymentModule is
    ICollectModule,
    ICollectPaymentModuleEventsAndErrors
{
    /// @notice Returns the collect payment info associated with an IP asset.
    /// @param  franchiseId_ The id of the franchise of the specified IP asset.
    /// @param  ipAssetId_ The id of the specified IP asset within the franchise.
    /// @return Payment info associated with the configured IP asset collect.
    function getPaymentInfo(
        uint256 franchiseId_,
        uint256 ipAssetId_
    ) external view returns (CollectPaymentInfo memory);

    /// @notice Initializes the collect payment module for a specific IP asset.
    /// @param initCollectParams_ Collect module init data, including IP asset
    ///        id, collect NFT impl address, and payment module init data.
    function initCollect(
        InitCollectParams calldata initCollectParams_
    ) external override(ICollectModule);

    /// @notice Performs a collect on a specific IP asset, processing the module
    ///         configured payment in the process.
    /// @param collectParams_ Collect module collect data, including IP asset id,
    ///         collector address, and collect payment module processing data.
    /// @return collectNft The address of the collected NFT.
    /// @return collectNftId The id of the collected collect NFT.
    function collect(
        CollectParams calldata collectParams_
    )
        external
        payable
        override(ICollectModule)
        returns (address collectNft, uint256 collectNftId);
}
