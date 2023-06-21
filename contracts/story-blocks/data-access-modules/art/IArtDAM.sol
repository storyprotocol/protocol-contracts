// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IStoryBlockStorage } from "../storage/IStoryBlockStorage.sol";

interface IArtDAM is IStoryBlockStorage {

    function createArt(string calldata name, string calldata _description, string calldata mediaUrl) external returns(uint256);
    function writeArt(uint256 id, string calldata name, string calldata _description, string calldata mediaUrl) external;
    function readArt(uint256 id) external view returns (StoryBlockData memory blockData);

}