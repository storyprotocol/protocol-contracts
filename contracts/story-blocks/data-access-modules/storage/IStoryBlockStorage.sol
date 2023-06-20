// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IStoryBlockAware } from "contracts/IStoryBlockAware.sol";

interface IStoryBlockStorage is IStoryBlockAware  {

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
    
}