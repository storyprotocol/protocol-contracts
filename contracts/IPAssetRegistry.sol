// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPAssetRegistry } from "contracts/interfaces/IIPAssetRegistry.sol";

/// @title IP Asset Registry
/// @notice The source of truth for IP on Story Protocol.
// TO-DO(@leeren): Add authorization around IP Asset registration and ownership transferring.
// TO-DO(ramarti): Add authorization around IP Asset Org transfer of IP Assets.
contract IPAssetRegistry is IIPAssetRegistry {

    /// @notice Core attributes that make up an IP Asset.
    // TO-DO: Add other core IP Asset primitives (namely module linking).
    struct IPAsset {
        address owner; // TO-DO: Consider removing this in the future.
        address ipAssetOrg;
    }

    /// @notice Mapping from IP asset ids to registry records.
    mapping(uint256 => IPAsset) ipAssets;

    /// @notice Tracks the total number of IP Assets in existence.
    uint256 numIPAssets = 0;

    /// @notice Registers a new IP Asset.
    /// @param owner_ The address of the IP Asset.
    /// @param ipAssetOrg_ The address of the IP Asset Org.
    // TO-DO(@leeren): Add registration authorization (likely based around IPOrg enrollment).
    // TO_DO(ramarti): Add module registration via resolver / registry.
    function register(address owner_, address ipAssetOrg_) public returns (uint256) {
        uint256 ipAssetId = numIPAssets++;
        ipAssets[ipAssetId] = IPAsset({
            owner: owner_,
            ipAssetOrg: ipAssetOrg_
        });

        emit IPAssetRegistered(ipAssetId, owner_, ipAssetOrg_);
        return ipAssetId;
    }

    function setOwner(uint256 ipAssetId_, address owner_) public {
        ipAssets[ipAssetId_].owner = owner_;
        emit OwnerTransferred(ipAssetId_, owner_);
    }

    function setIpOrg(uint256 ipAssetId_, address ipAssetOrg_) public {
        ipAssets[ipAssetId_].ipAssetOrg = ipAssetOrg_;
        emit OrgTransferred(ipAssetId_, ipAssetOrg_);
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
