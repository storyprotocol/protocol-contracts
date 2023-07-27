// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IRelationshipProcessor } from "./processors/IRelationshipProcessor.sol";
import { IPAsset } from "contracts/IPAsset.sol";


interface IRelationshipModule {

    event RelationSet(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 indexed relationshipId,
        uint256 endTime
    );
    event RelationUnset(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 indexed relationshipId
    );
    event RelationPendingProcessor(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 indexed relationshipId
    );

    event RelationshipConfigSet(
        bytes32 indexed relationshipId,
        uint256 sourceIPAssetTypeMask,
        uint256 destIPAssetTypeMask,
        bool onlySameFranchise,
        address processor,
        uint256 maxTTL,
        uint256 minTTL
    );

    event RelationshipConfigUnset(bytes32 indexed relationshipId);

    error NonExistingRelationship();
    error IntentAlreadyRegistered();
    error UnsupportedRelationshipSrc();
    error UnsupportedRelationshipDst();
    error CannotRelateToOtherFranchise();
    error InvalidTTL();
    error InvalidEndTimestamp();

    struct TimeConfig {
        uint112 maxTTL;
        uint112 minTTL;
        bool renewable;
    }

    struct RelationshipConfig {
        uint256 sourceIPAssetTypeMask;
        uint256 destIPAssetTypeMask;
        bool onlySameFranchise;
        IRelationshipProcessor processor;
        address disputer;
        TimeConfig timeConfig;
    }

    struct SetRelationshipConfigParams {
        IPAsset[] sourceIPAssets;
        bool allowedExternalSource;
        IPAsset[] destIPAssets;
        bool allowedExternalDest;
        bool onlySameFranchise;
        address processor;
        address disputer;
        TimeConfig timeConfig;
    }

    struct RelationshipParams {
        address sourceContract;
        uint256 sourceId;
        address destContract;
        uint256 destId;
        bytes32 relationshipId;
        uint256 ttl;
    }

    function relate(RelationshipParams calldata params, bytes calldata data) external;
    function unrelate(RelationshipParams calldata params) external;
    function areTheyRelated(RelationshipParams calldata params) external view returns (bool);
    function isRelationshipExpired(RelationshipParams calldata params) external view returns (bool);
    function setRelationshipConfig(bytes32 relationshipId, SetRelationshipConfigParams calldata params) external;
    function unsetRelationshipConfig(bytes32 relationshipId) external;
    function relationshipConfig(bytes32 relationshipId) external view returns (RelationshipConfig memory);
}