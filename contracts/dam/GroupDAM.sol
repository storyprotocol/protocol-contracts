// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPStorage } from "./IPStorage.sol";
import "../IStoryBlockAware.sol";
import { StoryBlocksRegistry } from "../franchises/StoryBlocksRegistry.sol";
import { FranchiseRegistry } from "../FranchiseRegistry.sol";

contract GroupDAM is IStoryBlockAware {

    
    IPStorage public immutable ipStorage;
    FranchiseRegistry public immutable franchiseRegistry;

    
    constructor(address _ipStorage, address _franchiseRegistry ) {
        ipStorage = IPStorage(_ipStorage);
        ipStorage.setAllowedBytesKey(PROTOCOL_ROOT_ID, keccak256("LINKED_ITEMS"));
        ipStorage.setAllowedUintKey(PROTOCOL_ROOT_ID, keccak256("LIKED_GROUP_TYPE"));
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
        ipStorage.writeBlockUintField(franchiseId, groupId, keccak256("LINKED_GROUP_TYPE"), uint256(linkedGroupType));
        // Set linked items
        for (uint256 i = 0; i < linkedItems.length; i++) {
            if (storyBlocksRegistry.storyBlockTypeFor(linkedItems[i]) != linkedGroupType) {
                revert("Invalid linked item");
            }
        }
        ipStorage.writeBlockBytesField(franchiseId, groupId, keccak256("LINKED_ITEMS"), abi.encode(linkedItems));
        // TODO: emit event
        return groupId;
    }

    function getGroup(uint256 franchiseId, uint256 groupId) external view returns(
        IPStorage.StoryBlockData memory data,
        StoryBlock linkedGroupType,
        uint256[] memory linkedItems
    ) {
        IPStorage.StoryBlockData memory sbd = ipStorage.readStoryBlock(franchiseId, groupId);
        linkedGroupType = StoryBlock(ipStorage.readBlockUintField(franchiseId, groupId, keccak256("LINKED_GROUP_TYPE")));
        linkedItems = abi.decode(ipStorage.readBlockBytesField(franchiseId, groupId, keccak256("LINKED_ITEMS")), (uint256[]));
        return (sbd, linkedGroupType, linkedItems);
    }



    
}