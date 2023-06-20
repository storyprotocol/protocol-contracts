// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IStoryBlockAware } from "contracts/IStoryBlockAware.sol";

library LibStoryBlockId {

    uint256 private constant _ID_RANGE = 10 ** 12;
    uint256 private constant _ZERO_ID_STORY = 0;
    uint256 private constant _ZERO_ID_CHARACTER = _ID_RANGE + _ZERO_ID_STORY;
    uint256 private constant _ZERO_ID_ART = _ID_RANGE + _ZERO_ID_CHARACTER;
    uint256 private constant _ZERO_ID_GROUP = _ID_RANGE + _ZERO_ID_ART;
    uint256 private constant _ZERO_ID_LOCATION = _ID_RANGE + _ZERO_ID_GROUP;
    uint256 private constant _LAST_ID = _ID_RANGE + _ZERO_ID_LOCATION;

    function zeroId(IStoryBlockAware.StoryBlock sb) public pure returns (uint256) {
        if (sb == IStoryBlockAware.StoryBlock.STORY) return _ZERO_ID_STORY;
        if (sb == IStoryBlockAware.StoryBlock.CHARACTER) return _ZERO_ID_CHARACTER;
        if (sb == IStoryBlockAware.StoryBlock.ART) return _ZERO_ID_ART;
        if (sb == IStoryBlockAware.StoryBlock.GROUP) return _ZERO_ID_GROUP;
        if (sb == IStoryBlockAware.StoryBlock.LOCATION) return _ZERO_ID_LOCATION;
        revert IStoryBlockAware.InvalidStoryBlock(sb);
    }

    function lastId(IStoryBlockAware.StoryBlock sb) public pure returns (uint256) {
        if (sb == IStoryBlockAware.StoryBlock.STORY) return _ZERO_ID_CHARACTER;
        if (sb == IStoryBlockAware.StoryBlock.CHARACTER) return _ZERO_ID_ART;
        if (sb == IStoryBlockAware.StoryBlock.ART) return _ZERO_ID_GROUP;
        if (sb == IStoryBlockAware.StoryBlock.GROUP) return _ZERO_ID_LOCATION;
        if (sb == IStoryBlockAware.StoryBlock.LOCATION) return _LAST_ID;
        revert IStoryBlockAware.InvalidStoryBlock(sb);
    }

    function storyBlockTypeFor(uint256 id) public pure returns (IStoryBlockAware.StoryBlock) {
        if (id > _ZERO_ID_STORY && id < _ZERO_ID_CHARACTER)
            return IStoryBlockAware.StoryBlock.STORY;
        if (id > _ZERO_ID_CHARACTER && id < _ZERO_ID_ART)
            return IStoryBlockAware.StoryBlock.CHARACTER;
        if (id > _ZERO_ID_ART && id < _ZERO_ID_GROUP) 
            return IStoryBlockAware.StoryBlock.ART;
        if (id > _ZERO_ID_GROUP && id < _ZERO_ID_LOCATION)
            return IStoryBlockAware.StoryBlock.GROUP;
        if (id > _ZERO_ID_LOCATION && id < _LAST_ID)
            return IStoryBlockAware.StoryBlock.LOCATION;
        return IStoryBlockAware.StoryBlock.UNDEFINED;
    }

}