// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/story-blocks/LibStoryBlockId.sol";
import "contracts/StoryBlock.sol";

contract FranchiseRegistryTest is Test {

    uint256 private constant _ID_RANGE = 10**12;
    uint256 private constant _HALF_ID_RANGE = 5**12;
    uint256 private constant _ZERO_ID_STORY = 0;
    uint256 private constant _ZERO_ID_CHARACTER = _ID_RANGE + _ZERO_ID_STORY;
    uint256 private constant _ZERO_ID_ART = _ID_RANGE + _ZERO_ID_CHARACTER;
    uint256 private constant _ZERO_ID_GROUP = _ID_RANGE + _ZERO_ID_ART;
    uint256 private constant _ZERO_ID_LOCATION = _ID_RANGE + _ZERO_ID_GROUP;
    uint256 private constant _ZERO_ID_ITEM = _ID_RANGE + _ZERO_ID_LOCATION;
    uint256 private constant _LAST_ID_ITEM = _ID_RANGE + _ZERO_ID_ITEM - 1;


    function test_zeroIds() public {
        assertEq(LibStoryBlockId.zeroId(StoryBlock.STORY), _ZERO_ID_STORY);
        assertEq(LibStoryBlockId.zeroId(StoryBlock.CHARACTER), _ZERO_ID_CHARACTER);
        assertEq(LibStoryBlockId.zeroId(StoryBlock.ART), _ZERO_ID_ART);
        assertEq(LibStoryBlockId.zeroId(StoryBlock.GROUP), _ZERO_ID_GROUP);
        assertEq(LibStoryBlockId.zeroId(StoryBlock.LOCATION), _ZERO_ID_LOCATION);
        assertEq(LibStoryBlockId.zeroId(StoryBlock.ITEM), _ZERO_ID_ITEM);
    }

    function test_lastIds() public {
        assertEq(LibStoryBlockId.lastId(StoryBlock.STORY), _ZERO_ID_CHARACTER - 1);
        assertEq(LibStoryBlockId.lastId(StoryBlock.CHARACTER), _ZERO_ID_ART - 1);
        assertEq(LibStoryBlockId.lastId(StoryBlock.ART), _ZERO_ID_GROUP - 1);
        assertEq(LibStoryBlockId.lastId(StoryBlock.GROUP), _ZERO_ID_LOCATION - 1);
        assertEq(LibStoryBlockId.lastId(StoryBlock.LOCATION), _ZERO_ID_ITEM - 1);
        assertEq(LibStoryBlockId.lastId(StoryBlock.ITEM), _LAST_ID_ITEM);
    }

    function test_storyBlockTypes() public {
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_STORY)), uint8(StoryBlock.UNDEFINED));

        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_STORY + 1)), uint8(StoryBlock.STORY));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_STORY + _HALF_ID_RANGE)), uint8(StoryBlock.STORY));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_CHARACTER - 1)), uint8(StoryBlock.STORY));
        
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_CHARACTER)), uint8(StoryBlock.UNDEFINED));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_CHARACTER + 1)), uint8(StoryBlock.CHARACTER));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_CHARACTER + _HALF_ID_RANGE)), uint8(StoryBlock.CHARACTER));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_ART - 1)), uint8(StoryBlock.CHARACTER));

        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_ART)), uint8(StoryBlock.UNDEFINED));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_ART + 1)), uint8(StoryBlock.ART));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_ART + _HALF_ID_RANGE)), uint8(StoryBlock.ART));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_GROUP - 1)), uint8(StoryBlock.ART));

        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_GROUP)), uint8(StoryBlock.UNDEFINED));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_GROUP + 1)), uint8(StoryBlock.GROUP));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_GROUP + _HALF_ID_RANGE)), uint8(StoryBlock.GROUP));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_LOCATION - 1)), uint8(StoryBlock.GROUP));

        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_LOCATION)), uint8(StoryBlock.UNDEFINED));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_LOCATION + 1)), uint8(StoryBlock.LOCATION));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_LOCATION + _HALF_ID_RANGE)), uint8(StoryBlock.LOCATION));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_ITEM - 1)), uint8(StoryBlock.LOCATION));

        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_ITEM)), uint8(StoryBlock.UNDEFINED));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_ITEM + 1)), uint8(StoryBlock.ITEM));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_ZERO_ID_ITEM + _HALF_ID_RANGE)), uint8(StoryBlock.ITEM));
        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_LAST_ID_ITEM)), uint8(StoryBlock.ITEM));

        assertEq(uint8(LibStoryBlockId.storyBlockTypeFor(_LAST_ID_ITEM + 1)), uint8(StoryBlock.UNDEFINED));
    }
}
