// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Global IP Asset Registry Interface
interface IIPAssetRegistry {
    /// @notice Emits when a new IP asset is registered.
    /// @param ipAssetId_ The global IP asset identifier.
    /// @param name_ The assigned name for the IP asset.
    /// @param ipOrg_ The registering governing body for the IP asset.
    /// @param registrant_ The initial individual registrant of the IP asset.
    /// @param hash_ The content hash associated with the IP asset.
    event Registered(
        uint256 ipAssetId_,
        string name_,
        address indexed ipOrg_,
        address indexed registrant_,
        bytes32 hash_
    );

    /// @notice Emits when an IP asset is transferred to a new IP Org.
    /// @param ipAssetId_ The identifier of the IP asset being transferred.
    /// @param oldIPOrg_ The original administering IP Org of the IP asset.
    /// @param newIPOrg_ The new administering IP Org of the IP asset.
    event IPOrgTransferred(uint256 indexed ipAssetId_, address indexed oldIPOrg_, address indexed newIPOrg_);

    /// @notice Emits when an IP asset has its status changed.
    /// @param ipAssetId_ The identifier of the IP asset whose status changed.
    /// @param oldStatus_ The original status associated with the IP asset.
    /// @param newStatus_ The new status associated with the IP asset.
    event StatusChanged(uint256 indexed ipAssetId_, uint8 oldStatus_, uint8 newStatus_);
}
