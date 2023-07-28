// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseRelationshipProcessor } from "./BaseRelationshipProcessor.sol";
import { IRelationshipModule } from "../IRelationshipModule.sol";
import { Unauthorized } from "contracts/errors/General.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title SrcRequestOrDstOwnerRelationshipProcessor
 * @dev Relationship processor that returns true if owner of destination, false if owner of source, reverts otherwise.
 */
contract SrcRequestOrDstOwnerRelationshipProcessor is BaseRelationshipProcessor {

    constructor(address relationshipModule) BaseRelationshipProcessor(relationshipModule) {}

    /**
     * Returns true.
     */
    function _processRelationship(IRelationshipModule.RelationshipParams memory params, bytes calldata, address caller) internal virtual override returns(bool) {
        if (IERC721(params.destContract).ownerOf(params.destId) == caller) {
            return true;
        } else if (IERC721(params.sourceContract).ownerOf(params.sourceId) == caller) {
            // Emits an event, which act as notification of pending relationship.
            return false;
        } else {
            revert Unauthorized();
        }
    }
}