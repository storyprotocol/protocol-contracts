// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IRelationshipModule } from "../IRelationshipModule.sol";

/**
 * @title IRelationshipProcessor
 * @dev Interface for relationship processors.
 * Relationship processors are used to process relationships between IP Assets before they are set.
 * They are set per relationship config in a IRelationshipModule
 */
interface IRelationshipProcessor {

    /**
     * @dev Processes a relationship between two IP Assets before it is set. This can be use for validity checks, actions, etc. It must:
     * - revert if the relationship is invalid
     * - return true if the relationship is valid and the relationship should be set immediately in the relationship module.
     * - return false if the relationship is valid but there is need for further processing. 
     *   In this case, the relationship module will emit a RelationPendingProcessor event.
     *   This can be leveraged for multi-step relationship setting, e.g. for a relationship that requires approval from the destination IP Asset owner.
     */
    function processRelationship(IRelationshipModule.RelationshipParams memory params, bytes calldata data, address caller) external returns(bool);
}