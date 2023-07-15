// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IRelationshipModule } from "../IRelationshipModule.sol";

interface IRelationshipProcessor {
    function processRelationship(IRelationshipModule.RelationshipParams memory params, bytes calldata data, address caller) external;
}