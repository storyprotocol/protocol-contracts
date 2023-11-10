// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title Relationship Module Library
library Registration {

    struct RegisterIPAParams {
        address owner;
        string name;
        uint64 ipAssetType;
        bytes32 hash;
    }

    bytes32 public constant ADD_METADATA_RENDERER_TYPE_CONFIG = keccak256("ADD_REL_TYPE");
    bytes32 public constant REMOVE_REL_TYPE_CONFIG = keccak256("REMOVE_REL_TYPE");
}
