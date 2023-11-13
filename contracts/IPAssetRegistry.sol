// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPAssetRegistry } from "contracts/interfaces/IIPAssetRegistry.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Global IP Asset Registry
/// @notice The source of truth for IP on Story Protocol.
contract IPAssetRegistry is IIPAssetRegistry {

    /// @notice Core attributes that make up an IP Asset.
    struct IPA {
        string name;                 // Human-readable identifier for the IP asset.
        uint64 ipAssetType;          // Numerical code corresponding to IP type (e.g. patent, copyright, etc.)
        address registrant;          // Address of the initial registrant of the IP asset.
        uint8 status;                // Current status of the IP asset (e.g. active, expired, etc.)
        address ipOrg;               // Address of the governing entity of the IP asset.
        bytes32 hash;                // A unique content hash of the IP asset for preserving integrity.
        uint64 registrationDate;     // Timestamp for which the IP asset was first registered.

    /// @notice Used for fetching modules associated with an IP asset.
    IModuleRegistry public immutable MODULE_REGISTRY;

    /// @notice Mapping from IP asset ids to registry records.
    mapping(uint256 => IPA) public ipAssets;

    /// @notice Tracks the total number of IP Assets in existence.
    /// TODO(leeren) Switch from numerical ids to a universal namehash.
    uint256 totalSupply = 0;

    /// @notice Restricts calls to the registration module of the IP Asset.
    /// TODO(ramarti): Enable IPOrg-specific registration modules to be authorized.
    modifier onlyRegistrationModule() {
        if (IModuleRegistry(_moduleRegistry).protocolModules(ModuleRegistryKeys.REGISTRATION_MODULE) != msg.sender) {
            revert Errors.Unauthorized();
        }
        _;
    }

    /// @notice Restricts calls to only being from the disputer for an IP asset.
    /// TODO(ramarti): Add authorization for calls that manage dispute lifecycle changes.
    modifier onlyDisputer(uint256 id) {
        _;
    }

    /// @notice Initializes the Global IP Asset Registry.
    /// @param moduleRegistry_ Address of the module registry.
    constructor(address moduleRegistry_) {
        MODULE_REGISTRY = moduleRegistry_;
    }
    
    /// @notice Registers a new IP asset.
    /// @param registrant_ The initial registrant for the IP asset.
    /// @param name_ A name given to describe the IP asset.
    /// @param ipAssetType_ A numerical code corresponding to IP asset type.
    /// @param hash_ A content hash used for verifyign provenance of the asset.
    function register(
        address registrant_,
        string name_,
        uint64 ipAssetType_,
        bytes32 hash_
    ) public onlyRegistrationModule returns (uint256 ipAssetId) {

        if (IModuleRegistry(_moduleRegistry).protocolModules(ModuleRegistryKeys.REGISTRATION_MODULE) != msg.sender) {
            revert Errors.Unauthorized();
        }

        // Crate a new IP asset with the provided IP attributes.
        ipAssetId = totalSupply++;
        uint64 registrationDate = uint64(block.timestamp);
        ipAssets[ipAssetId] = IPA({
            name: name_,
            ipAssetType: ipAssetType_,
            status: 0, // TODO(ramarti): Define status types.
            registrant: registrant_,
            ipOrg: msg.sender,
            hash: hash_,
            registrationDate: registrationDate,
        });
        emit Registered(
            ipAssetId,
            name_,
            ipAssetType_,
            msg.sender,
            registrant_,
            hash_
        );
    }

    /// @notice Changes the IP Org of an IP asset.
    /// @param ipAssetId_ The identifier of the IP asset being transferred.
    /// @param ipOrg_ The new IP Org to govern the IP asset.
    function transferIPOrg(uint256 ipAssetId_, address ipOrg_) public onlyRegistrationModule {
        uint8 oldIPOrg = ipAssets[ipAssetId_].ipOrg;
        ipAssets[ipAssetId_].ipOrg = ipOrg_;
        emit IPOrgTransferred(ipAssetId_, oldIPOrg, ipOrg_);
    }

    /// @notice Changes the status of an IP asset.
    /// @param ipAssetId_ The identifier of the IP asset being transferred.
    /// @param status_ The new status of the IP asset.
    /// TODO(ramarti) Finalize authorization logic around status changes.
    function setStatus(uint256 ipAssetId_, uint8 status_) public onlyDisputer(ipAssetId_) {
        uint8 oldStatus = ipAssets[ipAssetId_].status;
        ipAssets[ipAssetId_].status = status_;
        emit StatusChanged(ipAssetId_, oldStatus, status_);
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
