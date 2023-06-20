// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IStoryDAM } from "./IStoryDAM.sol";
import { StoryBlockStorage } from "../storage/StoryBlockStorage.sol";

abstract contract StoryDAM is IStoryDAM, StoryBlockStorage {

    function __StoryDAM_init() internal initializer {}

    function createStory(string calldata name, string calldata _description, string calldata mediaUrl) external returns(uint256) {
        uint256 id = _mintBlock(msg.sender, StoryBlock.STORY);
        _writeStoryBlock(id, name, _description, mediaUrl);
        return id;
    }

    function writeStory(uint256 id, string calldata name, string calldata _description, string calldata mediaUrl) external {
        _writeStoryBlock(id, name, _description, mediaUrl);
    }

    function readStory(uint256 id) public view returns (StoryBlockData memory blockData) {
        return readStoryBlock(id);
    }

}