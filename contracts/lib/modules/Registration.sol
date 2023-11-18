// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title Relationship Module Library
library Registration {

    /// @notice IPOrg configuration settings.
    struct IPOrgConfig {
        string baseURI;
        string contractURI;
        string[] assetTypes;
    }

    /// @notice Struct used for IP asset registration.
    struct RegisterIPAssetParams {
        address owner;
        string name;
        uint64 ipAssetType;
        bytes32 hash;
        string mediaUrl;
    }

    // TODO(leeren): Change in favor of granular function-selector based auth.

    // Constants used for determining module configuration logic.
    bytes32 public constant SET_IP_ORG_METADATA = keccak256("SET_IP_ORG_METADATA");
    bytes32 public constant SET_IP_ORG_ASSET_TYPES = keccak256("SET_IP_ORG_ASSET_TYPES");

    // Constants used for determining module execution logic.
    bytes32 public constant REGISTER_IP_ASSET = keccak256("REGISTER_IP_ASSET");
    bytes32 public constant TRANSFER_IP_ASSET = keccak256("TRANSFER_IP_ASSET");

}
