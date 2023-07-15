// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseRelationshipProcessor } from "./BaseRelationshipProcessor.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Unauthorized } from "contracts/errors/General.sol";
import { IRelationshipModule } from "../IRelationshipModule.sol";

contract DstRelationshipProcessor is BaseRelationshipProcessor {

    constructor(address relationshipModule) BaseRelationshipProcessor(relationshipModule) {}

    function _processRelationship(IRelationshipModule.RelationshipParams memory params, bytes calldata, address caller) internal view virtual override {
        if (IERC721(params.destContract).ownerOf(params.destId) != caller) {
            revert Unauthorized();
        }
    }

}