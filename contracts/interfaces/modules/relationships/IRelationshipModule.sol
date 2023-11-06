// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";

interface IRelationshipModule {

    event RelationshipTypeSet(
        string indexed relType,
        address indexed ipOrg,
        address src,
        LibRelationship.Relatables srcRelatable,
        uint256 srcSubtypesMask,
        address dst,
        LibRelationship.Relatables dstRelatable,
        uint256 dstSubtypesMask
    );

    event RelationshipTypeUnset(
        string indexed relType,
        address ipOrg
    );

    event RelationshipCreated(
        uint256 indexed relationshipId,
        string indexed relType,
        address srcAddress,
        uint256 srcId,
        address dstAddress,
        uint256 dstId
    );

    function getRelationshipType(address ipOrg_, string memory relType_) external view returns (LibRelationship.RelationshipType memory);
    function getRelationship(uint256 relationshipId_) external view returns (LibRelationship.Relationship memory);
    function getRelationshipId(LibRelationship.Relationship calldata rel_) external view returns (uint256);
    function relationshipExists(LibRelationship.Relationship calldata rel_) external view returns (bool);

    
}
