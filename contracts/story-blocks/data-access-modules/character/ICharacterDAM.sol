// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IStoryBlockStorage } from "../storage/IStoryBlockStorage.sol";

interface ICharacterDAM is IStoryBlockStorage {

    function createCharacter(string calldata name, string calldata _description, string calldata mediaUrl) external returns(uint256);
    function writeCharacter(uint256 id, string calldata name, string calldata _description, string calldata mediaUrl) external;
    function readCharacter(uint256 id) external view returns (StoryBlockData memory blockData);

}