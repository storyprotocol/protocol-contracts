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
    
}
