// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseRelationshipProcessor } from "./BaseRelationshipProcessor.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";


/// @title PermissionlessRelationshipProcessor
/// @dev Relationship processor that always returns true.
contract PermissionlessRelationshipProcessor is BaseRelationshipProcessor {

    constructor(address relationshipModule_) BaseRelationshipProcessor(relationshipModule_) {}

    
    /// Returns true.
    function _processRelationship(Relationship.RelationshipParams memory, bytes calldata, address) internal virtual override returns(bool) {
        return true;
    }
}
