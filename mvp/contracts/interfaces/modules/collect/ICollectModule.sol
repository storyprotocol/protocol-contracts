// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { Collect } from "contracts/lib/modules/Collect.sol";

/// @title Collect Module Interface
/// @notice The collect module enables IP assets to be minted as NFTs mirroring
///         their linking IP assets in a franchise-configurable format.
interface ICollectModule {

    /// @dev Emits when a Collect action is invoked.
    /// TODO: Add logging for franchise and ipAssetOrg
    event Collected(
        uint256 indexed ipAssetId_,
        address indexed collector_,
        address collectNft_,
        uint256 collectNftId_,
        bytes collectData_,
        bytes collectNftData_
    );

    /// @dev Emits when a new collect NFT is deployed.
    /// TODO: Add logging for franchise and ipAssetOrg
    event NewCollectNFT(
        uint256 indexed ipAssetId_,
        address collectNFT_
    );

    /// @notice Initializes the collect module for a specific IP asset.
    /// @param initCollectParams_ Collect module init data, including IP   asset
    ///        id, collect NFT impl address, and generic unformatted init data.
    function initCollect(Collect.InitCollectParams calldata initCollectParams_) external;

    /// @notice Performs a collect on a specific IP asset for a collector.
    /// @param collectParams_ Collect module collect data, including IP asset id,
    ///         collector address, and generic unformatted collect and NFT data.
    /// @return collectNft The address of the collected NFT.
    /// @return collectNftId The id of the collected collect NFT.
    function collect(
        Collect.CollectParams calldata collectParams_
    ) external payable returns (address collectNft, uint256 collectNftId);

    /// @notice Returns the collect NFT address associated with an IP asset.
    /// @param  ipAssetId_ The id of the specified IP asset within the franchise.
    /// @return The Collect NFT address if it exists, else the zero address.
    function getCollectNFT(
        uint256 ipAssetId_
    ) external returns (address);
}
