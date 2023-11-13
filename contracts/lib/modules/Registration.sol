// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title Relationship Module Library
library Registration {

    /// @notice IPOrg configuration settings.
    struct IPOrgConfig {
        string baseURI;
        string contractURI;
    }

    struct RegisterIPAParams {
        address owner;
        string name;
        uint64 ipAssetType;
        bytes32 hash;
    }

}
