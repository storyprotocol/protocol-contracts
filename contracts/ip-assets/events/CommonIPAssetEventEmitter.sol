// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPAssetEventEmitter } from "./IIPAssetEventEmitter.sol";
import { LibIPAssetId } from "contracts/ip-assets/LibIPAssetId.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";

contract CommonIPAssetEventEmitter is IIPAssetEventEmitter  {

    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    constructor(address _franchiseRegistry) {
        if (_franchiseRegistry == address(0)) revert ZeroAddress();
        FRANCHISE_REGISTRY = FranchiseRegistry(_franchiseRegistry);
    }

    function emitIPAssetCreation(uint256 franchiseId, uint256 ipAssetId) override external {
        if(FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId) != msg.sender) revert Unauthorized();
        emit IPAssetCreated(franchiseId, msg.sender, ipAssetId, LibIPAssetId._ipAssetTypeFor(ipAssetId));
    }

}