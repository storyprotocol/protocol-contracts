// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

uint256 constant PROTOCOL_ROOT_ID = 0;

interface IStoryBlockAware {

    enum StoryBlock {
        UNDEFINED,
        STORY,
        CHARACTER,
        ART,
        GROUP,
        LOCATION
    }
    
    error InvalidStoryBlock(StoryBlock sb);
}