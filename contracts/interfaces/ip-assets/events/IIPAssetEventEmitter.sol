// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/IPAsset.sol";

interface IIPAssetEventEmitter  {

    event IPAssetCreated(
        uint256 indexed franchiseId,
        address indexed ipAssetRegistry,
        uint256 ipAssetId,
        IPAsset ipAssetType
    );

    function emitIpAssetCreation(uint256 franchiseId_, uint256 ipAssetId_) external;

}