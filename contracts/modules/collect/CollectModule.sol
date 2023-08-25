// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ICollectModuleEventsAndErrors } from "../../interfaces/ICollectModuleEventsAndErrors.sol";
import { InitCollectParams, CollectParams } from "../../lib/CollectStructs.sol";
import { ICollectNFT } from "../../interfaces/ICollectNFT.sol";
import { ICollectModule } from "../../interfaces/ICollectModule.sol";

abstract contract CollectModule is AccessControlledUpgradeable, ICollectModule {

    address public immutable IP_ASSET_REGISTRY;
    address public immutable COLLECT_NFT_IMPL;

    // keccak256("story-protocol.simple-payment-collect-module.storage") - 1;
    bytes32 private constant _COLLECT_MODULE_STORAGE = 0xd16687d5cf786234491b4cc484b2a64f24855aadee9b1b73824db1ed2840fd0b;

    struct CollectModuleStorage {
        mapping(uint256 => address) collectNFTs;
    }

    modifier collectAuthorized(uint256 ipAssetId) {
        if (!_isCollectAuthorized(ipAssetId)) {
            revert CollectModuleCollectUnauthorized();
        }
        _;
    }

    constructor(address ipAssetRegistry, address collectNFTImpl) {
        IP_ASSET_REGISTRY = ipAssetRegistry;
        COLLECT_NFT_IMPL = collectNFTImpl;
        _disableInitializers();
    }

    function __CollectModule_init(address accessControl) internal onlyInitializing {
        __AccessControlledUpgradeable_init(accessControl);
        __CollectModule_init_unchained();
    }

    function __CollectModule_init_unchained() internal onlyInitializing {}

    function initialize(InitCollectParams calldata initParams) external {
        if (msg.sender != IP_ASSET_REGISTRY) {
            revert CollectModuleCallerUnauthorized();
        }
        _initializeCollect(initParams);
    }

    function collect(CollectParams calldata collectParams) collectAuthorized(collectParams.ipAssetId) external {
        address collectNFT = _getCollectNFT(collectParams.ipAssetId);
        ICollectNFT(collectNFT).collect(collectParams.collector);
        _collect(collectParams);
    }

    function _initializeCollect(InitCollectParams calldata initCollectParams) internal virtual;

    function _collect(CollectParams calldata collectParams) internal virtual;

    function _isCollectAuthorized(uint256 ipAssetId) internal view virtual returns (bool);

    function _getCollectNFT(uint256 ipAssetId) internal returns (address) {
        CollectModuleStorage storage $ = _getCollectModuleStorage();
        address collectNFT = $.collectNFTs[ipAssetId];
        if (collectNFT == address(0)) {
            collectNFT = Clones.clone(COLLECT_NFT_IMPL);
        }
        return collectNFT;
    }

    function _getCollectModuleStorage() private pure returns (CollectModuleStorage storage $) {
        assembly {
            $.slot := _COLLECT_MODULE_STORAGE
        }
    }

}
