// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { StoryBlock } from "contracts/StoryBlock.sol";

library LibStoryBlockId {

    error InvalidStoryBlock(StoryBlock sb);

    uint256 private constant _ID_RANGE = 10 ** 12;
    uint256 private constant _ZERO_ID_STORY = 0;
    uint256 private constant _LAST_ID_STORY = _ID_RANGE - 1 + _ZERO_ID_STORY;
    uint256 private constant _ZERO_ID_CHARACTER = _LAST_ID_STORY + 1;
    uint256 private constant _LAST_ID_CHARACTER = _ID_RANGE - 1 + _ZERO_ID_CHARACTER;
    uint256 private constant _ZERO_ID_ART = _LAST_ID_CHARACTER + 1;
    uint256 private constant _LAST_ID_ART = _ID_RANGE - 1 + _ZERO_ID_ART;
    uint256 private constant _ZERO_ID_GROUP = _LAST_ID_ART + 1;
    uint256 private constant _LAST_ID_GROUP = _ID_RANGE - 1 + _ZERO_ID_GROUP;
    uint256 private constant _ZERO_ID_LOCATION = _LAST_ID_GROUP + 1;
    uint256 private constant _LAST_ID_LOCATION = _ID_RANGE - 1 + _ZERO_ID_LOCATION;
    uint256 private constant _ZERO_ID_ITEM = _LAST_ID_LOCATION + 1;
    uint256 private constant _LAST_ID_ITEM = _ID_RANGE - 1 + _ZERO_ID_ITEM;

    function zeroId(StoryBlock sb) public pure returns (uint256) {
        if (sb == StoryBlock.STORY) return _ZERO_ID_STORY;
        if (sb == StoryBlock.CHARACTER) return _ZERO_ID_CHARACTER;
        if (sb == StoryBlock.ART) return _ZERO_ID_ART;
        if (sb == StoryBlock.GROUP) return _ZERO_ID_GROUP;
        if (sb == StoryBlock.LOCATION) return _ZERO_ID_LOCATION;
        if (sb == StoryBlock.ITEM) return _ZERO_ID_ITEM;
        revert InvalidStoryBlock(sb);
    }

    function lastId(StoryBlock sb) public pure returns (uint256) {
        if (sb == StoryBlock.STORY) return _LAST_ID_STORY;
        if (sb == StoryBlock.CHARACTER) return _LAST_ID_CHARACTER;
        if (sb == StoryBlock.ART) return _LAST_ID_ART;
        if (sb == StoryBlock.GROUP) return _LAST_ID_GROUP;
        if (sb == StoryBlock.LOCATION) return _LAST_ID_LOCATION;
        if (sb == StoryBlock.ITEM) return _LAST_ID_ITEM;
        revert InvalidStoryBlock(sb);
    }

    function storyBlockTypeFor(uint256 id) public pure returns (StoryBlock) {
        if (id > _ZERO_ID_STORY && id < _ZERO_ID_CHARACTER)
            return StoryBlock.STORY;
        if (id > _ZERO_ID_CHARACTER && id < _ZERO_ID_ART)
            return StoryBlock.CHARACTER;
        if (id > _ZERO_ID_ART && id < _ZERO_ID_GROUP) 
            return StoryBlock.ART;
        if (id > _ZERO_ID_GROUP && id < _ZERO_ID_LOCATION)
            return StoryBlock.GROUP;
        if (id > _ZERO_ID_LOCATION && id < _ZERO_ID_ITEM)
            return StoryBlock.LOCATION;
        if (id > _ZERO_ID_ITEM && id <= _LAST_ID_ITEM)
            return StoryBlock.ITEM;
        return StoryBlock.UNDEFINED;
    }

}