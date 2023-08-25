// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { InitCollectParams, CollectParams } from "../lib/CollectStructs.sol";
import { ICollectModuleEventsAndErrors } from "./ICollectModuleEventsAndErrors.sol";

/// @title Collect Module Interface
interface ICollectModule is ICollectModuleEventsAndErrors {

    function initializeCollect(InitCollectParams calldata initCollectParams) external;

    function collect(CollectParams calldata collectParams) external;

}
