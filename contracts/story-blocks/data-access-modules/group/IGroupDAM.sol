// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { StoryBlock } from "contracts/StoryBlock.sol";
import { IStoryBlockStorage } from "../storage/IStoryBlockStorage.sol";

interface IGroupDAM is IStoryBlockStorage {

    function createGroup(string calldata name, string calldata _description, string calldata mediaUrl, StoryBlock linkedType, uint256[] calldata linkedItems) external returns(uint256);
    function writeGroup(uint256 id, string calldata name, string calldata _description, string calldata mediaUrl, uint256[] calldata linkedItems) external;
    function readGroup(uint256 id) external view returns (StoryBlockData memory blockData, StoryBlock linkedType, uint256[] memory linkedItems);
    function groupItems(uint256 id, uint256[] calldata linkedItems) external;

}