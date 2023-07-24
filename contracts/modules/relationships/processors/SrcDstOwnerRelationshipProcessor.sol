// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseRelationshipProcessor } from "./BaseRelationshipProcessor.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Unauthorized } from "contracts/errors/General.sol";
import { IRelationshipModule } from "../IRelationshipModule.sol";

/**
 * @title SrcDstOwnerRelationshipProcessor
 * @dev Relationship processor that checks if the caller (relationship setter) is the owner of the source and destination IP Assets.
 */
contract SrcDstOwnerRelationshipProcessor is BaseRelationshipProcessor {

    constructor(address relationshipModule) BaseRelationshipProcessor(relationshipModule) {}

    /**
     * Returns true if the caller is the owner of the source and destination IP Assets, reverts otherwise.
     */
    function _processRelationship(IRelationshipModule.RelationshipParams memory params, bytes calldata, address caller) internal view virtual override returns(bool) {
        if (
            IERC721(params.sourceContract).ownerOf(params.sourceId) != caller ||
            IERC721(params.destContract).ownerOf(params.destId) != caller) {
            revert Unauthorized();
        }
        return true;
    }

}