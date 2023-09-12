// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { ICollectModule } from "contracts/interfaces/ICollectModule.sol";
import { ICollectModuleEventsAndErrors } from "contracts/interfaces/ICollectModuleEventsAndErrors.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";

import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { CollectInfo, InitCollectParams, CollectParams } from "contracts/lib/CollectModuleStructs.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";


/// @title Collect Module Base Implementation
/// @notice This is the Story Protocol base collect module that SHOULD be
///         extended when creating collect modules for franchise IP assets.
///         A collect module allows users to bind enrolled IP assets to NFTs
///         that may be minted according to franchise configured collect rules.
abstract contract CollectModuleBase is AccessControlledUpgradeable, ICollectModule {

    // The Story Protocol franchise registry - used for IP asset identification.
    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    // The default collect NFT impl address to be used for minting collect NFTs.
    address public immutable DEFAULT_COLLECT_NFT_IMPL;

    // The ERC-1967 storage slot associated with the collect module, given by:
    // keccak256("story-protocol.simple-payment-collect-module.storage") - 1;
    bytes32 private constant _COLLECT_MODULE_STORAGE = 0xd16687d5cf786234491b4cc484b2a64f24855aadee9b1b73824db1ed2840fd0b;

    // ERC-1967 style storage slots used for collect module storage.
    struct CollectModuleStorage {
        // Maps IP assets (franchiseId, ipAssetId) to collect module settings.
        mapping(uint256 => mapping(uint256 => CollectInfo)) collectInfo;
    }

    /// @notice Instantiates a new collect module.
    /// @param franchiseRegistry The protocol-wide franchise registry address.
    /// @param defaultCollectNFTImpl The default collect NFT impl address.
    constructor(address franchiseRegistry, address defaultCollectNFTImpl) {
        FRANCHISE_REGISTRY = FranchiseRegistry(franchiseRegistry);
        DEFAULT_COLLECT_NFT_IMPL = defaultCollectNFTImpl;
        _disableInitializers();
    }

    /// @notice Returns the collect NFT address associated with an IP asset.
    /// @param  franchiseId The id of the franchise of the specified IP asset.
    /// @param  ipAssetId The id of the specified IP asset within the franchise.
    /// @return The Collect NFT address if it exists, else the zero address.
    function getCollectNFT(uint256 franchiseId, uint256 ipAssetId) public view returns (address) {
        CollectInfo memory info = _getCollectModuleStorage().collectInfo[franchiseId][ipAssetId];
        return info.collectNFT;
    }

    /// @notice Initializes the collect module for a specific IP asset.
    /// @param initCollectParams Collect module init data, including IP asset
    ///        id, collect NFT impl address, and generic unformatted init data.
    /// @dev If no collect NFT impl address is passed, the default module-wide
    ///      collect NFT impl `DEFAULT_COLLECT_NFT_IMPL` will be used instead.
    function initCollect(InitCollectParams calldata initCollectParams) external {

        // An IP asset is identified by the tuple (franchiseId, ipAssetId).
        uint256 franchiseId = initCollectParams.franchiseId;
        uint256 ipAssetId = initCollectParams.ipAssetId;

        // Only the IP asset registry may initialize its asset's collect module.
        address collectNFTImpl = initCollectParams.collectNFTImpl;

        if (msg.sender != FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId)) {
            revert CollectModuleCallerUnauthorized();
        }

        // Revert if an IP asset collect module has already been initialized.
        CollectModuleStorage storage $ = _getCollectModuleStorage();
        if ($.collectInfo[franchiseId][ipAssetId].initialized) {
            revert CollectModuleIPAssetAlreadyInitialized();
        }

        // If an NFT impl address is not passed in, use the module default.
        if (collectNFTImpl != address(0)) {
            $.collectInfo[franchiseId][ipAssetId].collectNFTImpl = collectNFTImpl;
        }
        $.collectInfo[franchiseId][ipAssetId].initialized = true;

        // Perform any additional collect module initialization.
        _initCollect(initCollectParams);
    }

    /// @notice Performs a collect on a specific IP asset for a collector.
    /// @param collectParams Collect module collect data, including IP asset id,
    ///         collector address, and generic unformatted collect and NFT data.
    /// @dev When a collect is processed for the first time for an IP asset, the
    ///      collect NFT is deployed based on its configuered NFT impl address.
    /// @return collectNFT The address of the collected NFT.
    /// @return collectNFTId The id of the collected collect NFT.
    function collect(CollectParams calldata collectParams) external returns (address collectNFT, uint256 collectNFTId){

        // An IP asset is identified by the tuple (franchiseId, ipAssetId).
        uint256 franchiseId = collectParams.franchiseId;
        uint256 ipAssetId = collectParams.ipAssetId;

        // If collects are not authorized for the configured IP asset, revert.
        if (!_isCollectAuthorized(franchiseId, ipAssetId)) {
            revert CollectModuleCollectUnauthorized();
        }

        // Check that the specified IP asset actually exists.
        address ipAssetRegistry = FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId);
        if (ipAssetRegistry == address(0)) {
            revert CollectModuleIPAssetRegistryNonExistent();
        }
        try IIPAssetRegistry(ipAssetRegistry).ownerOf(ipAssetId) {
        } catch {
            revert CollectModuleIPAssetNonExistent();
        }

        // Get the bound collect NFT, deploying it if it has yet to exist.
        collectNFT = _getCollectNFT(franchiseId, ipAssetRegistry, ipAssetId, collectParams.collectNFTInitData);

        // Perform the collect, minting a collect NFT for the collector.
        collectNFTId = ICollectNFT(collectNFT).collect(collectParams.collector, collectParams.collectNFTData);

        // Perform any additional collect module processing.
        _collect(collectParams);

        return (collectNFT, collectNFTId);
    }

    /// @dev Perform any additional processing on collect module initialization.
    /// @param initCollectParams Collect module init data, including IP asset
    ///        id, collect NFT impl address, and generic unformatted init data.
    function _initCollect(InitCollectParams calldata initCollectParams) internal virtual {}

    /// @dev Perform any additional processing on collect module collection.
    /// @param collectParams Collect module collect data, including IP asset id,
    ///         collector address, and generic unformatted collect and NFT data.
    function _collect(CollectParams calldata collectParams) internal virtual {}

    /// @dev Performs any authorization on an IP asset collection.
    /// @param  franchiseId The id of the franchise of the specified IP asset.
    /// @param  ipAssetId The id of the specified IP asset within the franchise.
    function _isCollectAuthorized(uint256 franchiseId, uint256 ipAssetId) internal view virtual returns (bool);

    /// @dev Gets a collect NFT, deploying one if it does not yet exist.
    /// @param  franchiseId The id of the franchise of the specified IP asset.
    /// @param  ipAssetId The id of the specified IP asset within the franchise.
    /// @param  initData Additional unformatted collect NFT initialization data.
    function _getCollectNFT(uint256 franchiseId, address ipAssetRegistry, uint256 ipAssetId, bytes memory initData) internal returns (address) {

        // Retrieve the collect module settings for the IP asset.
        CollectModuleStorage storage $ = _getCollectModuleStorage();
        CollectInfo storage info = $.collectInfo[franchiseId][ipAssetId];
        if (!info.initialized) {
            revert CollectModuleCollectNotYetInitialized();
        }
        address collectNFT = info.collectNFT;

        // If the collect NFT does not yet exist, deploy and initialize it.
        if (collectNFT == address(0)) {
            address collectNFTImpl = info.collectNFTImpl;

            // If a custom collect NFT impementation is configured, use it, else 
            // default to the franchise-wide collect NFT implementation.
            collectNFT = collectNFTImpl == address(0) ? Clones.clone(DEFAULT_COLLECT_NFT_IMPL) : Clones.clone(collectNFTImpl);

            // Perform collect NFT initialization for the IP asset.
            ICollectNFT(collectNFT).initialize(InitCollectNFTParams({
                ipAssetRegistry: ipAssetRegistry,
                ipAssetId: ipAssetId,
                data: initData
            }));
            $.collectInfo[franchiseId][ipAssetId].collectNFT = collectNFT;
        }
        return collectNFT;
    }

    /// @dev Gets the ERC-1967 configured collect module storage slot.
    function _getCollectModuleStorage() private pure returns (CollectModuleStorage storage $) {
        assembly {
            $.slot := _COLLECT_MODULE_STORAGE
        }
    }
}
