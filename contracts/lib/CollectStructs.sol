// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

    struct InitCollectParams {
        uint256 ipAssetId;
        address collectNFT;
        bytes moduleData;
        bytes nftData;
    }

    struct CollectParams {
        uint256 ipAssetId;
        address collector;
        bytes data;
    }
