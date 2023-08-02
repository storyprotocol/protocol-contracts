// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/IPAsset.sol";

interface IIPAssetDataManager  {

    event IPAssetWritten(
        uint256 indexed IPAssetId,
        IPAsset indexed blockType,
        string name,
        string description,
        string mediaUrl
    );

    struct IPAssetData {
        string name;
        string description;
        string mediaUrl;
        IPAsset blockType;
    }
    
    function readIPAsset(uint256 IPAssetId) external view returns (IPAssetData memory);
    
    function createIPAsset(
        IPAsset sb,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl
    ) external returns (uint256);
    
}