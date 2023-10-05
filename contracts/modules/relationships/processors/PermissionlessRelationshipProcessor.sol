// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseRelationshipProcessor } from "./BaseRelationshipProcessor.sol";
import { IRelationshipModule } from "contracts/interfaces/modules/relationships/IRelationshipModule.sol";


/// @title PermissionlessRelationshipProcessor
/// @dev Relationship processor that always returns true.
contract PermissionlessRelationshipProcessor is BaseRelationshipProcessor {

    constructor(address relationshipModule) BaseRelationshipProcessor(relationshipModule) {}

    
    /// Returns true.
    function _processRelationship(IRelationshipModule.RelationshipParams memory, bytes calldata, address) internal virtual override returns(bool) {
        return true;
    }
}