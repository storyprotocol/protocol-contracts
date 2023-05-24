// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

interface IStoryBlockAware {

    enum StoryBlock {
        STORY,
        CHARACTER,
        ART,
        GROUP,
        LOCATION
    }
    
    error InvalidStoryBlock(StoryBlock sb);
}