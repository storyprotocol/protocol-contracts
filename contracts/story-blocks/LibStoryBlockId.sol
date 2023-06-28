// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { StoryBlock } from "contracts/StoryBlock.sol";

library LibStoryBlockId {

    error InvalidStoryBlock(StoryBlock sb);

    uint256 private constant _ID_RANGE = 10 ** 12;

    function _zeroId(StoryBlock sb) internal pure returns (uint256) {
        if (sb == StoryBlock.UNDEFINED) revert InvalidStoryBlock(sb);
        return _ID_RANGE * (uint256(sb) - 1);
    }

    function _lastId(StoryBlock sb) internal pure returns (uint256) {
        if (sb == StoryBlock.UNDEFINED) revert InvalidStoryBlock(sb);
        return (_ID_RANGE * uint256(sb)) - 1;
    }

    function _storyBlockTypeFor(uint256 id) internal pure returns (StoryBlock) {
        // End of _ID_RANGE is zero (undefined) for each StoryBlock
        // Also, we don't support ids higher than the last StoryBlock enum item
        if (id % _ID_RANGE == 0 || id > _ID_RANGE * (uint256(StoryBlock.ITEM))) return StoryBlock.UNDEFINED;
        return StoryBlock((id / _ID_RANGE) + 1);
    }

}