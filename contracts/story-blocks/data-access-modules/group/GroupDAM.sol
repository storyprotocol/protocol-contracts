// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IGroupDAM } from "./IGroupDAM.sol";
import { StoryBlockStorage } from "../storage/StoryBlockStorage.sol";
import { LibStoryBlockId } from "contracts/story-blocks/LibStoryBlockId.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { StoryBlock } from "contracts/StoryBlock.sol";

abstract contract GroupDAM is IGroupDAM, StoryBlockStorage {

    using EnumerableSet for EnumerableSet.UintSet;

    struct GroupData {
        StoryBlock linkedType;
        EnumerableSet.UintSet linkedItems;
    }

    event GroupedItems(
        uint256 indexed id,
        StoryBlock linkedType,
        uint256[] linkedItems
    );
    error TooManyLinkedItems();
    error GroupedTypeNotGroupType();

    mapping(uint256 => GroupData) private _groupData;

    uint256 public constant MAX_LINKED_AT_ONCE = 20;

    function __GroupDAM_init() internal initializer {}

    function createGroup(string calldata name, string calldata _description, string calldata mediaUrl, StoryBlock linkedType, uint256[] calldata linkedItems) external returns(uint256) {
        uint256 id = createStoryBlock(StoryBlock.GROUP, name, _description, mediaUrl);
        _groupData[id].linkedType = linkedType;
        groupItems(id, linkedItems);
        return id;
    }

    function groupItems(uint256 id, uint256[] calldata linkedItems) public {
        uint256 length = linkedItems.length;
        if (length > MAX_LINKED_AT_ONCE) revert TooManyLinkedItems();
        StoryBlock linkedType = _groupData[id].linkedType;
        for(uint256 i = 0; i < linkedItems.length;) {
            if (LibStoryBlockId.storyBlockTypeFor(linkedItems[i]) != linkedType) revert GroupedTypeNotGroupType();
            _groupData[id].linkedItems.add(linkedItems[i]);
            unchecked {
                i++;
            }
        }
        emit GroupedItems(id, linkedType, linkedItems);
    }

    function readGroup(uint256 id) public view returns (StoryBlockData memory blockData, StoryBlock linkedType, uint256[] memory linkedItems) {
        blockData = readStoryBlock(id);
        GroupData storage gd = _groupData[id];
        linkedType = gd.linkedType;
        linkedItems = gd.linkedItems.values();
    }



}