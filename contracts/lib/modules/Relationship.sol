// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/lib/IPAsset.sol";
import { IRelationshipProcessor } from "contracts/interfaces/modules/relationships/processors/IRelationshipProcessor.sol";

/// @title Relationship Module Library
library Relationship {

    /// @notice Configures relationship TTLs and renewals.
    struct TimeConfig {
        uint112 maxTtl;
        uint112 minTtl;
        bool renewable;
    }

    /// @notice Core relationship module configuration.
    struct RelationshipConfig {
        uint256 sourceIpAssetTypeMask;
        uint256 destIpAssetTypeMask;
        bool onlySameIPAssetOrg;
        IRelationshipProcessor processor;
        address disputer;
        TimeConfig timeConfig;
    }

    /// @notice Core relationship module setter configuration.
    struct SetRelationshipConfigParams {
        IPAsset.IPAssetType[] sourceIpAssets;
        bool allowedExternalSource;
        IPAsset.IPAssetType[] destIpAssets;
        bool allowedExternalDest;
        bool onlySameIPAssetOrg;
        address processor;
        address disputer;
        TimeConfig timeConfig;
    }

    /// @notice Core relationship parameters.
    struct RelationshipParams {
        address sourceContract;
        uint256 sourceId;
        address destContract;
        uint256 destId;
        bytes32 relationshipId;
        uint256 ttl;
    }

}
