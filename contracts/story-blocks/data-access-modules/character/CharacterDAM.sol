// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ICharacterDAM } from "./ICharacterDAM.sol";
import { StoryBlockStorage } from "../storage/StoryBlockStorage.sol";
import { LibStoryBlockId } from "contracts/story-blocks/block-ids/LibStoryBlockId.sol";

abstract contract CharacterDAM is ICharacterDAM, StoryBlockStorage {

    function __CharacterDAM_init() internal initializer {}

    function createCharacter(string calldata name, string calldata _description, string calldata mediaUrl) external returns(uint256) {
        uint256 id = _mintBlock(msg.sender, StoryBlock.CHARACTER);
        _writeStoryBlock(id, name, _description, mediaUrl);
        return id;
    }

    function writeCharacter(uint256 id, string calldata name, string calldata _description, string calldata mediaUrl) external {
        _writeStoryBlock(id, name, _description, mediaUrl);
    }

    function readCharacter(uint256 id) public view returns (StoryBlockData memory blockData) {
        return readStoryBlock(id);
    }
    
}