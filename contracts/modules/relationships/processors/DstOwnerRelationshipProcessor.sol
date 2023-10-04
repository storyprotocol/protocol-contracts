// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseRelationshipProcessor } from "./BaseRelationshipProcessor.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Unauthorized } from "contracts/errors/General.sol";
import { IRelationshipModule } from "contracts/interfaces/modules/relationships/IRelationshipModule.sol";

/**
 * @title DstOwnerRelationshipProcessor
 * @dev Relationship processor that checks if the caller (relationship setter) is the owner of the destination IP Asset.
 */
contract DstOwnerRelationshipProcessor is BaseRelationshipProcessor {

    constructor(address relationshipModule) BaseRelationshipProcessor(relationshipModule) {}

    /**
     * Returns true if the caller is the owner of the destination IP Asset, reverts otherwise.
     */
    function _processRelationship(IRelationshipModule.RelationshipParams memory params, bytes calldata, address caller) internal view virtual override returns(bool) {
        if (IERC721(params.destContract).ownerOf(params.destId) != caller) {
            revert Unauthorized();
        }
        return true;
    }

}