// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IStoryBlockAware } from "contracts/IStoryBlockAware.sol";
import { IStoryBlockStorage } from "../storage/IStoryBlockStorage.sol";

interface ILocationDAM is IStoryBlockAware, IStoryBlockStorage {

    function createLocation(string calldata name, string calldata _description, string calldata mediaUrl) external returns(uint256);
    function writeLocation(uint256 id, string calldata name, string calldata _description, string calldata mediaUrl) external;
    function readLocation(uint256 id) external view returns (StoryBlockData memory blockData);

}