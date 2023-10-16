// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/lib/IPAsset.sol";

interface IIPAssetGroupDataManager  {

    event IPAssetWritten(
        uint256 indexed ipAssetId,
        IPAsset.IPAssetType indexed blockType,
        string name,
        string description,
        string mediaUrl
    );

    struct IPAssetData {
        string name;
        string description;
        string mediaUrl;
        uint256 ipAssetId;
        IPAsset.IPAssetType blockType;
    }
    
    function readIPAsset(uint256 ipAssetId_) external view returns (IPAssetData memory);
    
}
