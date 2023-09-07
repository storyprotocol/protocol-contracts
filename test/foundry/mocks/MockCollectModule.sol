// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { CollectModuleBase } from "contracts/modules/collect/CollectModuleBase.sol";

contract MockCollectModuleConstants {

    uint256 public constant UNAUTHORIZED_FRANCHISE_ID = 99;
}

contract MockCollectModule is CollectModuleBase, MockCollectModuleConstants {


    mapping(uint256 => mapping(uint256 => bool)) collectEnabled;

    constructor(address ipAssetRegistry, address collectNFTImpl) CollectModuleBase(ipAssetRegistry, collectNFTImpl) {}

    function initialize(address accessControl) public initializer {
        __CollectModuleBase_init(accessControl);
    }

    function _isCollectAuthorized(uint256 franchiseId, uint256 ipAssetId) internal view override returns (bool) {
        return franchiseId != UNAUTHORIZED_FRANCHISE_ID;
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}
