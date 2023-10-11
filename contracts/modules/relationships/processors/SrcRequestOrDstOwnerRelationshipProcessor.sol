// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseRelationshipProcessor } from "./BaseRelationshipProcessor.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";
import { Errors } from "contracts/lib/Errors.sol";


/// @title SrcRequestOrDstOwnerRelationshipProcessor
/// @dev Relationship processor that returns true if owner of destination, false if owner of source, reverts otherwise.
contract SrcRequestOrDstOwnerRelationshipProcessor is BaseRelationshipProcessor {

    constructor(address relationshipModule_) BaseRelationshipProcessor(relationshipModule_) {}

    /// Returns true if destination owner, false if source owner (to signal a link request), reverts otherwise.
    function _processRelationship(Relationship.RelationshipParams memory params_, bytes calldata, address caller_) internal virtual override returns(bool) {
        if (IERC721(params_.destContract).ownerOf(params_.destId) == caller_) {
            return true;
        } else if (IERC721(params_.sourceContract).ownerOf(params_.sourceId) == caller_) {
            // Emits an event, which act as notification of pending relationship.
            return false;
        } else {
            revert Errors.Unauthorized();
        }
    }
}
