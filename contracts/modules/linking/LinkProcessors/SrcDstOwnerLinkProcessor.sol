// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseLinkProcessor } from "./BaseLinkProcessor.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Unauthorized } from "contracts/errors/General.sol";
import { ILinkingModule } from "../ILinkingModule.sol";

contract SrcDstOwnerLinkProcessor is BaseLinkProcessor {

    constructor(address linkingModule) BaseLinkProcessor(linkingModule) {}

    function _processLink(ILinkingModule.LinkParams memory params, bytes calldata, address linker) internal view virtual override {
        if (
            IERC721(params.sourceContract).ownerOf(params.sourceId) != linker ||
            IERC721(params.destContract).ownerOf(params.destId) != linker) {
            revert Unauthorized();
        }
    }

}