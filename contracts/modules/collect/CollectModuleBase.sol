// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ICollectModuleEventsAndErrors } from "../../interfaces/ICollectModuleEventsAndErrors.sol";
import { CollectInfo, InitCollectParams, CollectParams } from "../../lib/CollectModuleStructs.sol";
import { InitCollectNFTParams } from "../../lib/CollectNFTStructs.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";
import { ICollectNFT } from "../../interfaces/ICollectNFT.sol";
import { ICollectModule } from "../../interfaces/ICollectModule.sol";

/// @title Collect Module Base Implementation
abstract contract CollectModuleBase is AccessControlledUpgradeable, ICollectModule {

    FranchiseRegistry public immutable FRANCHISE_REGISTRY;
    address public immutable DEFAULT_COLLECT_NFT_IMPL;

    // keccak256("story-protocol.simple-payment-collect-module.storage") - 1;
    bytes32 private constant _COLLECT_MODULE_STORAGE = 0xd16687d5cf786234491b4cc484b2a64f24855aadee9b1b73824db1ed2840fd0b;

    struct CollectModuleStorage {
        mapping(uint256 => mapping(uint256 => CollectInfo)) collectInfo;
    }

    constructor(address franchiseRegistry, address defaultCollectNFTImpl) {
        FRANCHISE_REGISTRY = FranchiseRegistry(franchiseRegistry);
        DEFAULT_COLLECT_NFT_IMPL = defaultCollectNFTImpl;
        _disableInitializers();
    }

    function __CollectModuleBase_init(address accessControl) internal onlyInitializing {
        __AccessControlledUpgradeable_init(accessControl);
        __CollectModuleBase_init_unchained();
    }

    function __CollectModuleBase_init_unchained() internal onlyInitializing {}

    function getCollectNFT(uint256 franchiseId, uint256 ipAssetId) public view returns (address) {
        CollectInfo memory info = _getCollectModuleStorage().collectInfo[franchiseId][ipAssetId];
        return info.collectNFT;
    }

    function initCollect(InitCollectParams calldata initParams) external {
        uint256 franchiseId = initParams.franchiseId;
        address collectNFTImpl = initParams.collectNFTImpl;
        if (msg.sender != FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId)) {
            revert CollectModuleCallerUnauthorized();
        }

        uint256 ipAssetId = initParams.ipAssetId;
        CollectModuleStorage storage $ = _getCollectModuleStorage();
        if ($.collectInfo[franchiseId][ipAssetId].initialized) {
            revert CollectModuleIPAssetAlreadyInitialized();
        }

        if (collectNFTImpl != address(0)) {
            $.collectInfo[franchiseId][ipAssetId].collectNFTImpl = collectNFTImpl;
        }
        $.collectInfo[franchiseId][ipAssetId].initialized = true;
        _initCollect(initParams);
    }

    function collect(CollectParams calldata collectParams) external returns (address collectNFT, uint256 collectNFTId){
        uint256 franchiseId = collectParams.franchiseId;
        uint256 ipAssetId = collectParams.ipAssetId;
        if (!_isCollectAuthorized(franchiseId, ipAssetId)) {
            revert CollectModuleCollectUnauthorized();
        }
        address ipAssetRegistry = FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId);
        if (ipAssetRegistry == address(0)) {
            revert CollectModuleIPAssetRegistryNonExistent();
        }
        try IIPAssetRegistry(ipAssetRegistry).ownerOf(ipAssetId) {
        } catch {
            revert CollectModuleIPAssetNonExistent();
        }
        collectNFT = _getCollectNFT(franchiseId, ipAssetRegistry, ipAssetId, collectParams.collectNFTInitData);
        collectNFTId = ICollectNFT(collectNFT).collect(collectParams.collector, collectParams.collectNFTData);
        _collect(collectParams);
        return (collectNFT, collectNFTId);
    }

    function _initCollect(InitCollectParams calldata initCollectParams) internal virtual {}

    function _collect(CollectParams calldata collectParams) internal virtual {}

    function _isCollectAuthorized(uint256 franchiseId, uint256 ipAssetId) internal view virtual returns (bool);

    function _getCollectNFT(uint256 franchiseId, address ipAssetRegistry, uint256 ipAssetId, bytes memory initData) internal returns (address) {
        CollectModuleStorage storage $ = _getCollectModuleStorage();
        CollectInfo storage info = $.collectInfo[franchiseId][ipAssetId];
        if (!info.initialized) {
            revert CollectModuleCollectNotYetInitialized();
        }
        address collectNFT = info.collectNFT;
        if (collectNFT == address(0)) {
            address collectNFTImpl = info.collectNFTImpl;
            collectNFT = collectNFTImpl == address(0) ? Clones.clone(DEFAULT_COLLECT_NFT_IMPL) : Clones.clone(collectNFTImpl);
            ICollectNFT(collectNFT).initialize(InitCollectNFTParams({
                ipAssetRegistry: ipAssetRegistry,
                ipAssetId: ipAssetId,
                data: initData
            }));
            $.collectInfo[franchiseId][ipAssetId].collectNFT = collectNFT;
        }
        return collectNFT;
    }

    function _getCollectModuleStorage() private pure returns (CollectModuleStorage storage $) {
        assembly {
            $.slot := _COLLECT_MODULE_STORAGE
        }
    }

}
