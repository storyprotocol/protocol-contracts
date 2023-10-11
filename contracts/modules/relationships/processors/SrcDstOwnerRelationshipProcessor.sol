// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseRelationshipProcessor } from "./BaseRelationshipProcessor.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";
import { Errors } from "contracts/lib/Errors.sol";


/// @title SrcDstOwnerRelationshipProcessor
/// @dev Relationship processor that checks if the caller (relationship setter) is the owner of the source and destination IP Assets.
contract SrcDstOwnerRelationshipProcessor is BaseRelationshipProcessor {

    constructor(address relationshipModule_) BaseRelationshipProcessor(relationshipModule_) {}

    
    /// Returns true if the caller is the owner of the source and destination IP Assets, reverts otherwise.
    function _processRelationship(Relationship.RelationshipParams memory params_, bytes calldata, address caller_) internal view virtual override returns(bool) {
        if (
            IERC721(params_.sourceContract).ownerOf(params_.sourceId) != caller_ ||
            IERC721(params_.destContract).ownerOf(params_.destId) != caller_) {
            revert Errors.Unauthorized();
        }
        return true;
    }

}
