// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPAssetEventEmitter } from "contracts/interfaces/ip-assets/events/IIPAssetEventEmitter.sol";
import { LibIPAssetID } from "contracts/ip-assets/LibIPAssetID.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";

contract CommonIPAssetEventEmitter is IIPAssetEventEmitter  {

    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    constructor(address franchiseRegistry_) {
        if (franchiseRegistry_ == address(0)) revert ZeroAddress();
        FRANCHISE_REGISTRY = FranchiseRegistry(franchiseRegistry_);
    }

    function emitIpAssetCreation(uint256 franchiseId_, uint256 ipAssetId_) override external {
        if(FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId_) != msg.sender) revert Unauthorized();
        emit IPAssetCreated(franchiseId_, msg.sender, ipAssetId_, LibIPAssetID._ipAssetTypeFor(ipAssetId_));
    }

}