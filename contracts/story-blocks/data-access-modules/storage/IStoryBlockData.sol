// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { StoryBlock } from "contracts/StoryBlock.sol";

interface IStoryBlockData  {

    event StoryBlockWritten(
        uint256 indexed storyBlockId,
        StoryBlock indexed blockType,
        string name,
        string description,
        string mediaUrl
    );

    struct StoryBlockData {
        string name;
        string description;
        string mediaUrl;
        StoryBlock blockType;
    }
    
    function readStoryBlock(uint256 storyBlockId) external view returns (StoryBlockData memory);
    
    function createStoryBlock(
        StoryBlock sb,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl
    ) external returns (uint256);
    
}