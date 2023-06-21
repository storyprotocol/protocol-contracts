// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IGroupDAM } from "./IGroupDAM.sol";
import { StoryBlockStorage } from "../storage/StoryBlockStorage.sol";
import { LibStoryBlockId } from "contracts/story-blocks/LibStoryBlockId.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IStoryBlockAware } from "contracts/IStoryBlockAware.sol";

abstract contract GroupDAM is IGroupDAM, StoryBlockStorage {

    using EnumerableSet for EnumerableSet.UintSet;

    struct GroupData {
        IStoryBlockAware.StoryBlock linkedType;
        EnumerableSet.UintSet linkedItems;
    }

    event GroupedItems(
        uint256 indexed id,
        IStoryBlockAware.StoryBlock linkedType,
        uint256[] linkedItems
    );
    error TooManyLinkedItems();

    mapping(uint256 => GroupData) private _groupData;

    uint256 public constant MAX_LINKED_AT_ONCE = 20;

    function __GroupDAM_init() internal initializer {}

    function createGroup(string calldata name, string calldata _description, string calldata mediaUrl, IStoryBlockAware.StoryBlock linkedType, uint256[] calldata linkedItems) external returns(uint256) {
        uint256 id = _mintBlock(msg.sender, IStoryBlockAware.StoryBlock.GROUP);
        _writeStoryBlock(id, name, _description, mediaUrl);
        _groupData[id].linkedType = linkedType;
        groupItems(id, linkedItems);
        return id;
    }

    function writeGroup(uint256 id, string calldata name, string calldata _description, string calldata mediaUrl, uint256[] calldata linkedItems) external {
        _writeStoryBlock(id, name, _description, mediaUrl);
        groupItems(id, linkedItems);
    }

    function groupItems(uint256 id, uint256[] calldata linkedItems) public {
        uint256 length = linkedItems.length;
        if (length > MAX_LINKED_AT_ONCE) revert TooManyLinkedItems();
        IStoryBlockAware.StoryBlock linkedType = _groupData[id].linkedType;
        for(uint256 i = 0; i < linkedItems.length;) {
            if (LibStoryBlockId.storyBlockTypeFor(linkedItems[i]) != linkedType) revert OverridingBlockType();
            _groupData[id].linkedItems.add(linkedItems[i]);
            unchecked {
                i++;
            }
        }
        emit GroupedItems(id, linkedType, linkedItems);
    }

    function readGroup(uint256 id) public view returns (StoryBlockData memory blockData, IStoryBlockAware.StoryBlock linkedType, uint256[] memory linkedItems) {
        blockData = readStoryBlock(id);
        GroupData storage gd = _groupData[id];
        linkedType = gd.linkedType;
        linkedItems = gd.linkedItems.values();
    }



}