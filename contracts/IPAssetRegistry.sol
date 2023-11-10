// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPAssetRegistry } from "contracts/interfaces/IIPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

/// @title Global IP Asset Registry
/// @notice The source of truth for IP on Story Protocol.
contract IPAssetRegistry is IIPAssetRegistry {

    /// @notice Core attributes that make up an IP Asset.
    struct IPA {
        string name;                 // Human-readable identifier for the IP asset.
        uint64 ipAssetType;          // Numerical code corresponding to IP type (e.g. patent, copyright, etc.)
        uint8 status;                // Current status of the IP asset (e.g. active, expired, etc.)
        address owner;               // Address of the current owner of the IP asset.
        address initialRegistrant;   // Address of the initial registrant of the IP asset.
        address ipOrg;               // Address of the governing entity of the IP asset.
        bytes32 hash;                // A unique content hash of the IP asset for preserving integrity.
        uint64 registrationDate;     // Timestamp for which the IP asset was first registered.
    }

    uint256 public immutable IP_ORG_CONTROLLER;

    /// @notice Mapping from IP asset ids to registry records.
    mapping(uint256 => IPA) public ipAssets;

    /// @notice Tracks the total number of IP Assets in existence.
    uint256 numIPAssets = 0;

    /// @notice Restricts calls to only authorized IP Orgs of the IP Asset.
    /// TODO(leeren): Add authorization around IP owner once IP Orgs are done.
    modifier onlyIPOrg(uint256 id) {
        // Ensure the caller is an enrolled IPOrg.
        if (!IP_ORG_CONTROLLER.isIPOrg(msg.sender)) {
            revert Errors.Unauthorized();
        }

        // If the IP is already enrolled, ensure the caller is its IP Org.
        address ipOrg = ipAssets[id].ipOrg;
        if (ipOrg != address(0) && ipOrg != msg.sender) {
            revert Errors.Unauthorized();
        }
        _;
    }

    /// @notice Restricts calls to only being from the disputer of an IP asset.
    /// TODO(ramarti): Add authorization for calls that manage dispute lifecycle changes.
    modifier onlyDisputer(uint256 id) {
        _;
    }

    /// @notice Initializes the Global IP Asset Registry.
    /// @param ipOrgController Address of the IP Org Controller contract.
    constructor(address ipOrgController_) {
        IP_ORG_CONTROLLER = ipOrgController_;
    }
    
    /// @notice Registers a new IP Asset.
    /// @param params_ The IP asset registration parameters.
    // TODO(ramarti): Add registration authorization via registration module.
    // TODO(ramarti): Include module parameters and interfacing to registration.
    function register(
        address owner_,
        string name_,
        uint64 ipAssetType_,
        bytes32 hash_
    ) public returns (uint256) {
        uint256 ipAssetId = numIPAssets++;
        uint64 registrationDate = uint64(block.timestamp);

        ipAssets[ipAssetId] = IPA({
            name: name_,
            ipAssetType: ipAssetType_,
            status: 0, // TODO(ramarti): Define status types.
            owner: owner_,
            initialRegistrant: owner_,
            ipOrg: msg.sender,
            hash: hash_,
            registrationDate: registrationDate,
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
    function setStatus(uint256 ipAssetId_, uint8 status_) public onlyDisputer(ipAssetId_) {
        uint8 oldStatus = ipAssets[ipAssetId_].status;
        ipAssets[ipAssetId_].status = status_;
        emit IPAssetStatusChanged(ipAssetId_, oldStatus, status_);
    }

    /// @notice Transfers ownership of an IP asset to a new owner.
    /// @param ipAssetId_ The identifier of the IP asset being transferred.
    /// @param owner_ The new owner of the IP asset.
    /// TODO(leeren) Add authorization around IPOrg transferring rights.
    function setOwner(uint256 ipAssetId_, address owner_) public onlyAuthorized(ipAssetId_) {
        address prevOwner = ipAssets[ipAssetId_].owner;
        ipAssets[ipAssetId_].owner = owner_;
        emit IPAssetTransferred(ipAssetId_, prevOwner, owner_);
    }

    /// @notice Gets the owner of a specific IP Asset.
    /// @param ipAssetId_ The id of the IP Asset being queried.
    function getOwner(uint256 ipAssetId_) public view returns (address) {
        return ipAssets[ipAssetId_].owner;
    }

    /// @notice Gets the status for a specific IP Asset.
    /// @param ipAssetId_ The id of the IP Asset being queried.
    function getStatus(uint256 ipAssetId_) public view returns (uint8) {
        return ipAssets[ipAssetId_].status;
    }

    /// @notice Gets the IP Asset Org that administers a specific IP Asset.
    /// @param ipAssetId_ The id of the IP Asset being queried.
    function getIPOrg(uint256 ipAssetId_) public view returns (address) {
        return ipAssets[ipAssetId_].ipOrg;
    }

}
