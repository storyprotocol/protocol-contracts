// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPAssetRegistry } from "contracts/interfaces/IIPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

/// @title Global IP Asset Registry
/// @notice The source of truth for IP on Story Protocol.
// TO-DO(@leeren): Migrate from consecutive ids to a global namehashing scheme.
contract IPAssetRegistry is IIPAssetRegistry {

    /// @notice Mapping from IP asset ids to registry records.
    mapping(uint256 => IPAsset.IPA) public ipAssets;

    /// @notice Tracks the total number of IP Assets in existence.
    uint256 numIPAssets = 0;

    /// @notice Restricts calls to only being from the owner or IPOrg of an IP asset.
    /// TODO(leeren): Add more cohesive authorization once the core alpha refactor is completed.
    modifier onlyAuthorized(uint256 id) {
        address ipOrg = ipAssets[id].ipOrg;
        address owner = ipAssets[id].owner;
        if (msg.sender != owner || msg.sender != ipOrg) {
            revert Errors.Unauthorized();
        }
        _;
    }

    /// @notice Restricts calls to only being from the disputer of an IP asset.
    /// TODO(ramarti): Add authorization for calls that manage dispute lifecycle changes.
    modifier onlyDisputer(uint256 id) {
        _;
    }

    /// @notice Registers a new IP Asset.
    /// @param params_ The IP asset registration parameters.
    // TODO(ramarti): Add registration authorization via registration module.
    // TODO(ramarti): Include module parameters and interfacing to registration.
    function register(IPAsset.RegisterIpAssetParams calldata params_) public returns (uint256) {
        uint256 ipAssetId = numIPAssets++;
        uint64 registrationDate = uint64(block.timestamp);

        ipAssets[ipAssetId] = IPAsset.IPA({
            name: params_.name,
            ipAssetType: params_.ipAssetType,
            status: 0, // TODO(ramarti): Define status types.
            owner: params_.owner,
            initialRegistrant: params_.owner,
            ipOrg: params_.ipOrg,
            hash: params_.hash,
            url: params_.url,
            registrationDate: registrationDate,
            data: params_.data
        });

        emit IPAssetRegistered(
            ipAssetId,
            params_.ipAssetType,
            params_.owner,
            params_.ipOrg,
            params_.hash
        );

        emit IPAssetTransferred(ipAssetId, address(0), params_.owner);

        return ipAssetId;
    }

    /// @notice Changes the status of an IP asset..
    /// @param ipAssetId_ The identifier of the IP asset being transferred.
    /// @param status_ The new status of the IP asset.
    /// TODO(ramarti) Finalize authorization logic around the disputer.
    function setIPAssetStatus(uint256 ipAssetId_, uint8 status_) public onlyDisputer(ipAssetId_) {
        uint8 oldStatus = ipAssets[ipAssetId_].status;
        ipAssets[ipAssetId_].status = status_;
        emit IPAssetStatusChanged(ipAssetId_, oldStatus, status_);
    }

    /// @notice Transfers ownership of an IP asset to a new owner.
    /// @param ipAssetId_ The identifier of the IP asset being transferred.
    /// @param owner_ The new owner of the IP asset.
    /// TODO(leeren) Add authorization around IPOrg transferring rights.
    function setIPAssetOwner(uint256 ipAssetId_, address owner_) public onlyAuthorized(ipAssetId_) {
        address prevOwner = ipAssets[ipAssetId_].owner;
        ipAssets[ipAssetId_].owner = owner_;
        emit IPAssetTransferred(ipAssetId_, prevOwner, owner_);
    }

    /// @notice Gets the owner of a specific IP Asset.
    /// @param ipAssetId_ The id of the IP Asset being queried.
    function ipAssetOwner(uint256 ipAssetId_) public view returns (address) {
        return ipAssets[ipAssetId_].owner;
    }

    /// @notice Gets the status for a specific IP Asset.
    /// @param ipAssetId_ The id of the IP Asset being queried.
    function ipAssetStatus(uint256 ipAssetId_) public view returns (uint8) {
        return ipAssets[ipAssetId_].status;
    }

    /// @notice Gets the IP Asset Org that administers a specific IP Asset.
    /// @param ipAssetId_ The id of the IP Asset being queried.
    function ipAssetOrg(uint256 ipAssetId_) public view returns (address) {
        return ipAssets[ipAssetId_].ipOrg;
    }

}
