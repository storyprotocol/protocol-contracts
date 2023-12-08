// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

/// @title IP Asset Library
/// @notice Library for constants, structs, and helper functions for IP assets.
library IPAsset {
    /// @notice Core attributes that make up an IP Asset.
    struct IPA {
        string name; // Human-readable identifier for the IP asset.
        address registrant; // Address of the initial registrant of the IP asset.
        uint8 status; // Current status of the IP asset (e.g. active, expired, etc.)
        address ipOrg; // Address of the governing entity of the IP asset.
        bytes32 hash; // A unique content hash of the IP asset for preserving integrity.
        uint64 registrationDate; // Timestamp for which the IP asset was first registered.
    }

    /// @notice Struct for packing parameters related to IP asset registration.
    struct RegisterIpAssetParams {
        string name;
        uint8 ipOrgAssetType;
        address owner;
        bytes32 hash;
        string mediaUrl;
    }
}
