// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/IPAsset.sol";

interface IIPAssetDataManager  {

    event IPAssetWritten(
        uint256 indexed ipAssetId,
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
    
    function readIPAsset(uint256 ipAssetId) external view returns (IPAssetData memory);
    
}