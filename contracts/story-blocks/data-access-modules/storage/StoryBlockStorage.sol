// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { LibStoryBlockId } from "contracts/story-blocks/LibStoryBlockId.sol";
import { Unauthorized, NonExistentID } from "contracts/errors/General.sol";
import { IStoryBlockStorage } from "./IStoryBlockStorage.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { StoryBlock } from "contracts/StoryBlock.sol";

abstract contract StoryBlockStorage is Initializable, IStoryBlockStorage {

    error InvalidBlockType();

    // storyblockId -> data
    mapping(uint256 => StoryBlockData) private _storyBlocks;

    function createStoryBlock(
        StoryBlock sb,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl
    ) public returns (uint256) {
        if (sb == StoryBlock.UNDEFINED) revert InvalidBlockType();
        uint256 sbId = _mintBlock(msg.sender, sb);
        _writeStoryBlock(sbId, name, _description, mediaUrl);
        return sbId;
    }
    
    function _writeStoryBlock(
        uint256 storyBlockId,
        string calldata name,
        string calldata description,
        string calldata mediaUrl
    ) private returns (StoryBlock) {
        StoryBlockData storage sbd = _storyBlocks[storyBlockId];
        if (sbd.blockType == StoryBlock.UNDEFINED) {
            sbd.blockType = LibStoryBlockId.storyBlockTypeFor(storyBlockId);
        }
        sbd.name = name;
        sbd.description = description;
        sbd.mediaUrl = mediaUrl;
        emit StoryBlockWritten(storyBlockId, sbd.blockType, name, description, mediaUrl);
        return sbd.blockType;
    }

    function readStoryBlock(uint256 storyBlockId) public view returns (StoryBlockData memory) {
        return _storyBlocks[storyBlockId];
    }
    
    function _mintBlock(address to, StoryBlock sb) internal virtual returns (uint256);
}