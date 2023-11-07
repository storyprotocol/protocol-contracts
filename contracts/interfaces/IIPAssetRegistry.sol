import { IPAsset } from "contracts/lib/IPAsset.sol";

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title Global IP Asset Registry Contract Interface
interface IIPAssetRegistry {

    /// @notice Emits when a new IP asset is registered.
    event IPAssetRegistered(
        uint256 ipAssetId_,
        uint64 indexed ipAssetType_,
        address indexed owner_,
        address indexed ipAssetOrg_,
        bytes32 hash_
    );

    /// @notice Emits when an IP asset is transferred to a new owner.
    event IPAssetTransferred(
        uint256 indexed ipAssetId_,
        address indexed from_,
        address indexed to_
    );

    /// @notice Emits when an IP asset has its status changed.
    event IPAssetStatusChanged(
        uint256 indexed ipAssetId_,
        uint8 oldStatus_,
        uint8 newStatus_
    );

}
