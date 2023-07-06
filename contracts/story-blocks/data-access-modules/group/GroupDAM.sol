// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IGroupDAM } from "./IGroupDAM.sol";
import { StoryBlockData } from "../storage/StoryBlockData.sol";
import { LibStoryBlockId } from "contracts/story-blocks/LibStoryBlockId.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { StoryBlock } from "contracts/StoryBlock.sol";

abstract contract GroupDAM is IGroupDAM, StoryBlockData {

    using EnumerableSet for EnumerableSet.UintSet;

    event GroupedItems(
        uint256 indexed id,
        StoryBlock linkedType,
        uint256[] linkedItems
    );
    
    error TooManyLinkedItems();
    error GroupedTypeNotGroupType();

    struct GroupData {
        StoryBlock linkedType;
        EnumerableSet.UintSet linkedItems;
    }
    /// @custom:storage-location erc7201:story-protocol.group-dam.storage
    struct GroupDAMStorage {
        mapping(uint256 => GroupData) groupData;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.group-dam.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x472b429d656ecfb82e6e0cff4b4090577a009a43252b08434ed2201373a9647d;
    uint256 public constant MAX_LINKED_AT_ONCE = 20;

    function __GroupDAM_init() internal initializer {}

    function _getGroupDAMStorage() private pure returns (GroupDAMStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function createGroup(string calldata name, string calldata _description, string calldata mediaUrl, StoryBlock linkedType, uint256[] calldata linkedItems) external returns(uint256) {
        uint256 id = createStoryBlock(StoryBlock.GROUP, name, _description, mediaUrl);
        GroupDAMStorage storage $ = _getGroupDAMStorage();
        $.groupData[id].linkedType = linkedType;
        groupItems(id, linkedItems);
        return id;
    }

    function groupItems(uint256 id, uint256[] calldata linkedItems) public {
        uint256 length = linkedItems.length;
        if (length > MAX_LINKED_AT_ONCE) revert TooManyLinkedItems();
        GroupDAMStorage storage $ = _getGroupDAMStorage();
        StoryBlock linkedType = $.groupData[id].linkedType;
        for(uint256 i = 0; i < linkedItems.length;) {
            if (LibStoryBlockId._storyBlockTypeFor(linkedItems[i]) != linkedType) revert GroupedTypeNotGroupType();
            $.groupData[id].linkedItems.add(linkedItems[i]);
            unchecked {
                i++;
            }
        }
        emit GroupedItems(id, linkedType, linkedItems);
    }

    function readGroup(uint256 id) public view returns (StoryBlockData memory blockData, StoryBlock linkedType, uint256[] memory linkedItems) {
        blockData = readStoryBlock(id);
        GroupDAMStorage storage $ = _getGroupDAMStorage();
        GroupData storage gd = $.groupData[id];
        linkedType = gd.linkedType;
        linkedItems = gd.linkedItems.values();
    }

}