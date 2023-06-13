// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPStorage } from "./IPStorage.sol";
import "../IStoryBlockAware.sol";
import { StoryBlocksRegistry } from "../franchises/StoryBlocksRegistry.sol";
import { FranchiseRegistry } from "../FranchiseRegistry.sol";

contract GroupDAMIndependent is IStoryBlockAware {

    IPStorage public immutable ipStorage;
    FranchiseRegistry public immutable franchiseRegistry;

    mapping(uint256 => mapping(uint256 => StoryBlock)) private _groupedTypes;
    mapping(uint256 => mapping(uint256 => uint256[])) private _groupedItems;

    constructor(address _ipStorage, address _franchiseRegistry ) {
        ipStorage = IPStorage(_ipStorage);
        franchiseRegistry = FranchiseRegistry(_franchiseRegistry);
    }


    function createGroup(
        uint256 franchiseId,
        uint256 storyBlockId,
        string calldata name,
        string calldata description,
        string calldata mediaUrl,
        StoryBlock linkedGroupType,
        uint256[] calldata linkedItems
    ) external returns(uint256) {
        StoryBlocksRegistry storyBlocksRegistry = StoryBlocksRegistry(franchiseRegistry.storyBlocksContract(franchiseId));
        require(storyBlocksRegistry.ownerOf(storyBlockId) == msg.sender, "Unauthorized");
        // Mint group id
        uint256 groupId = storyBlocksRegistry.mint(msg.sender, StoryBlock.GROUP);
        // Name it
        ipStorage.writeStoryBlock(
            franchiseId,
            groupId,
            StoryBlock.GROUP,
            name,
            description,
            mediaUrl
        );
        // Set linked group type
        _groupedTypes[franchiseId][groupId] = linkedGroupType;
        // Set linked items
        for (uint256 i = 0; i < linkedItems.length; i++) {
            if (storyBlocksRegistry.storyBlockTypeFor(linkedItems[i]) != linkedGroupType) {
                revert("Invalid linked item");
            }
        }
        _groupedItems[franchiseId][groupId] = linkedItems;
        // TODO: emit event
        return groupId;
    }

    function getGroup(uint256 franchiseId, uint256 groupId) external view returns(
        IPStorage.StoryBlockData memory data,
        StoryBlock linkedGroupType,
        uint256[] memory linkedItems
    ) {
        IPStorage.StoryBlockData memory sbd = ipStorage.readStoryBlock(franchiseId, groupId);
        linkedGroupType = _groupedTypes[franchiseId][groupId];
        linkedItems = _groupedItems[franchiseId][groupId];
        return (sbd, linkedGroupType, linkedItems);
    }



    
}