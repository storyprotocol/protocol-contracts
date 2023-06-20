// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IArtDAM } from "./IArtDAM.sol";
import { StoryBlockStorage } from "../storage/StoryBlockStorage.sol";
import { LibStoryBlockId } from "contracts/story-blocks/block-ids/LibStoryBlockId.sol";

abstract contract ArtDAM is StoryBlockStorage, IArtDAM {

    function __ArtDAM_init() internal initializer {}

    function createArt(string calldata name, string calldata _description, string calldata mediaUrl) external returns(uint256) {
        uint256 id = _mintBlock(msg.sender, StoryBlock.LOCATION);
        _writeStoryBlock(id, name, _description, mediaUrl);
        return id;
    }

    function writeArt(uint256 id, string calldata name, string calldata _description, string calldata mediaUrl) external {
        _writeStoryBlock(id, name, _description, mediaUrl);
    }

    function readArt(uint256 id) public view returns (StoryBlockData memory blockData) {
        return readStoryBlock(id);
    }

}