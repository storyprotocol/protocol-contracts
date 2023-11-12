// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/lib/IPAsset.sol";
import { Errors } from "./Errors.sol";

/// @title IP Asset Library
/// @notice Library for constants, structs, and helper functions for IP assets.
library IPAsset {
    uint8 public constant EXTERNAL_ASSET = type(uint8).max;

    uint256 private constant _ID_RANGE = 10 ** 12;

    /// @notice Core attributes that make up an IP Asset.
    struct IPA {
        string name;                 // Human-readable identifier for the IP asset.
        uint64 ipAssetType;          // Numerical code corresponding to IP type (e.g. patent, copyright, etc.)
        uint8 status;                // Current status of the IP asset (e.g. active, expired, etc.)
        address owner;               // Address of the current owner of the IP asset.
        address initialRegistrant;   // Address of the initial registrant of the IP asset.
        address ipOrg;               // Address of the governing entity of the IP asset.
        bytes32 hash;                // A unique content hash of the IP asset for preserving integrity.
        string url;                  // URL linked to additional metadata for the IP asset.
        uint64 registrationDate;     // Timestamp for which the IP asset was first registered.
        bytes data;                  // Any additional data to be tied to the IP asset.
    }

    enum IPAssetType {
        UNDEFINED,
        STORY,
        CHARACTER,
        ART,
        GROUP,
        LOCATION,
        ITEM
    }

    /// @notice Struct for packing parameters related to IP asset registration.
    struct RegisterIpAssetParams {
        string name;
        uint64 ipAssetType;
        address owner;
        address ipOrg;
        bytes32 hash;
        string url;
        bytes data;
    }

    struct CreateIpAssetParams {
        IPAsset.IPAssetType ipAssetType;
        string name;
        string description;
        string mediaUrl;
        address to;
        uint256 parentIpOrgId;
        bytes collectData;
    }

}
