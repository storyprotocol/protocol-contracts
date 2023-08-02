// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/IPAsset.sol";
import { IIPAssetDataManager } from "../storage/IIPAssetDataManager.sol";

interface IGroupDAM is IIPAssetDataManager {

    function createGroup(string calldata name, string calldata _description, string calldata mediaUrl, IPAsset linkedType, uint256[] calldata linkedItems) external returns(uint256);
    function readGroup(uint256 id) external view returns (IPAssetData memory blockData, IPAsset linkedType, uint256[] memory linkedItems);
    function groupItems(uint256 id, uint256[] calldata linkedItems) external;

}