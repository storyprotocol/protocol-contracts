// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { LibStoryBlockId } from "contracts/story-blocks/LibStoryBlockId.sol";
import { Unauthorized, NonExistentID } from "contracts/errors/General.sol";
import { IStoryBlockData } from "./IStoryBlockData.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { StoryBlock } from "contracts/StoryBlock.sol";

abstract contract StoryBlockData is Initializable, IStoryBlockData {

    error InvalidBlockType();

    /// @custom:storage-location erc7201:story-protocol.story-block-data.storage
    struct StoryBlockDataStorage {
        mapping(uint256 => StoryBlockData) storyBlocks;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.story-block-data.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x966cf815c9bea5bfddba7716d33fe72d80930319e8b0b6565972e93128571d28;

    function __StoryBlockData_init() public initializer {}

    function _getStoryBlockDataStorage() private pure returns (StoryBlockDataStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function createStoryBlock(
        StoryBlock sb,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl
    ) public returns (uint256) {
        if (sb == StoryBlock.UNDEFINED) revert InvalidBlockType();
        uint256 sbId = _mintBlock(msg.sender, sb);
        _writeStoryBlock(sbId, name, _description, mediaUrl);
        return sbId;
    }
    
    function _writeStoryBlock(
        uint256 storyBlockId,
        string calldata name,
        string calldata description,
        string calldata mediaUrl
    ) private returns (StoryBlock) {
        StoryBlockDataStorage storage $ = _getStoryBlockDataStorage();
        StoryBlockData storage sbd = $.storyBlocks[storyBlockId];
        if (sbd.blockType == StoryBlock.UNDEFINED) {
            sbd.blockType = LibStoryBlockId._storyBlockTypeFor(storyBlockId);
        }
        sbd.name = name;
        sbd.description = description;
        sbd.mediaUrl = mediaUrl;
        emit StoryBlockWritten(storyBlockId, sbd.blockType, name, description, mediaUrl);
        return sbd.blockType;
    }

    function readStoryBlock(uint256 storyBlockId) public view returns (StoryBlockData memory) {
        StoryBlockDataStorage storage $ = _getStoryBlockDataStorage();
        return $.storyBlocks[storyBlockId];
    }
    
    function _mintBlock(address to, StoryBlock sb) internal virtual returns (uint256);
}