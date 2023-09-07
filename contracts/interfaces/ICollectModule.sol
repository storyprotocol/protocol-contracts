// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { InitCollectParams, CollectParams } from "../lib/CollectModuleStructs.sol";
import { ICollectModuleEventsAndErrors } from "./ICollectModuleEventsAndErrors.sol";

/// @title Collect Module Interface
interface ICollectModule is ICollectModuleEventsAndErrors {

    function initCollect(InitCollectParams calldata initCollectParams) external;

    function collect(CollectParams calldata collectParams) external;

    function getCollectNFT(uint256 franchiseId, uint256 ipAssetId) external returns (address);

}
