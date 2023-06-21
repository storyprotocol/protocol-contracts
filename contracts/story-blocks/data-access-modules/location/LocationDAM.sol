// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ILocationDAM } from "./ILocationDAM.sol";
import { StoryBlockStorage } from "../storage/StoryBlockStorage.sol";
import { StoryBlock } from "contracts/StoryBlock.sol";

abstract contract LocationDAM is ILocationDAM, StoryBlockStorage {

    function __LocationDAM_init() internal initializer {}

    function createLocation(string calldata name, string calldata _description, string calldata mediaUrl) external returns(uint256) {
        uint256 id = _mintBlock(msg.sender, StoryBlock.LOCATION);
        _writeStoryBlock(id, name, _description, mediaUrl);
        return id;
    }

    function writeLocation(uint256 id, string calldata name, string calldata _description, string calldata mediaUrl) external {
        _writeStoryBlock(id, name, _description, mediaUrl);
    }

    function readLocation(uint256 id) public view returns (StoryBlockData memory blockData) {
        return readStoryBlock(id);
    }

}