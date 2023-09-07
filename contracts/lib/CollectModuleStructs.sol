// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

struct InitCollectParams {
    uint256 franchiseId;
    uint256 ipAssetId;
    address collectNFTImpl;
    bytes data;
}

struct CollectParams {
    uint256 franchiseId;
    uint256 ipAssetId;
    address collector;
    bytes collectData;
    bytes collectNFTInitData;
    bytes collectNFTData;
}

struct CollectInfo {
    bool initialized;
    address collectNFT;
    address collectNFTImpl;
}
