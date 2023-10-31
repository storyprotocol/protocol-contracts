// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IRelationshipProcessor } from "./processors/IRelationshipProcessor.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";

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
        string name,
        bytes32 indexed relationshipId,
        uint256 sourceIpAssetTypeMask,
        uint256 destIpAssetTypeMask,
        bool onlySameIPAssetOrg,
        address processor,
        uint256 maxTtl,
        uint256 minTtl,
        bool renewable
    );

    event RelationshipConfigUnset(bytes32 indexed relationshipId);

    function relate(Relationship.RelationshipParams calldata params_, bytes calldata data_) external;
    function unrelate(Relationship.RelationshipParams calldata params_) external;
    function areTheyRelated(Relationship.RelationshipParams calldata params_) external view returns (bool);
    function isRelationshipExpired(Relationship.RelationshipParams calldata params_) external view returns (bool);
    function setRelationshipConfig(string calldata name_, Relationship.SetRelationshipConfigParams calldata params_) external returns(bytes32 relationshipId);
    function getRelationshipId(string calldata name_) external view returns (bytes32);
    function unsetRelationshipConfig(bytes32 relationshipId_) external;
    function getRelationshipConfig(bytes32 relationshipId_) external view returns (Relationship.RelationshipConfig memory);
    function getRelationshipConfigDecoded(bytes32 relationshipId_) external view returns (Relationship.SetRelationshipConfigParams memory);
}
