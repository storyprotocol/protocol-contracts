// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPAssetEventEmitter } from "contracts/ip-assets/events/IIPAssetEventEmitter.sol";

contract MockIPAssetEventEmitter is IIPAssetEventEmitter  {

    function emitIPAssetCreation(uint256, uint256) override external {
        // no-op
    }

}