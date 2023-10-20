// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title IP Asset Registry
/// @notice The source of truth for IP on Story Protocol.
// TO-DO(@leeren): Add authorization around IP Asset registration and ownership transferring.
// TO-DO(ramarti): Add authorization around IP Asset Org transfer of IP Assets.
contract IPAssetRegistry {

    /// @notice Core attributes that make up an IP Asset.
    // TO-DO: Add other core IP Asset primitives (namely module linking).
    struct IPAsset {
        address owner;
        address ipAssetOrg;
    }

    /// @notice Mapping from IP asset ids to registry records.
    mapping(uint256 => IPAsset) ipAssets;

    /// @notice Tracks the total number of IP Assets in existence.
    uint256 numIPAssets = 0;

    /// @notice Registers a new IP Asset.
    /// @param owner_ The address of the IP Asset.
    /// @param ipAssetOrg_ The address of the IP Asset Org.
    // TO-DO(@leeren): Add registration authorization (likely based around IPAssetOrg enrollment).
    // TO_DO(ramarti): Add module registration via resolver / registry.
    function register(address owner_, address ipAssetOrg_) public returns (uint256) {
        uint256 ipAssetId = numIPAssets++;
        ipAssets[ipAssetId] = IPAsset({
            owner: owner_,
            ipAssetOrg: ipAssetOrg_
        });
        return ipAssetId;
    }

    /// @notice Gets the IP Asset Org that administers a specific IP Asset.
    /// @param ipAssetId_ The id of the IP Asset being queried.
    function ipAssetOrg(uint256 ipAssetId_) public returns (address) {
        return ipAssets[ipAssetId_].ipAssetOrg;
    }

    /// @notice Gets the owner of a specific IP Asset.
    /// @param ipAssetId_ The id of the IP Asset being queried.
    function ipAssetOwner(uint256 ipAssetId_) public returns (address) {
        return ipAssets[ipAssetId_].owner;
    }

}
