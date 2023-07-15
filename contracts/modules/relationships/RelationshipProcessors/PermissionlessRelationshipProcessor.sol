// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseRelationshipProcessor } from "./BaseRelationshipProcessor.sol";
import { IRelationshipModule } from "../IRelationshipModule.sol";

contract PermissionlessRelationshipProcessor is BaseRelationshipProcessor {

    constructor(address relationshipModule) BaseRelationshipProcessor(relationshipModule) {}

    function _processRelationship(IRelationshipModule.RelationshipParams memory, bytes calldata, address) internal virtual override returns(bool) {
        return true;
    }
}