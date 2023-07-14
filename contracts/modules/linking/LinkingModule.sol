// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ZeroAddress, UnsupportedInterface } from "contracts/errors/General.sol";
import { UPGRADER_ROLE, LINK_MANAGER_ROLE, LINK_DISPUTER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";
import { LinkIPAssetTypeChecker } from "./LinkIPAssetTypeChecker.sol";
import { ILinkingModule } from "./ILinkingModule.sol";
import { ILinkProcessor } from "./LinkProcessors/ILinkProcessor.sol";
import "forge-std/console.sol";

contract LinkingModule is ILinkingModule, AccessControlledUpgradeable, LinkIPAssetTypeChecker {
    using ERC165CheckerUpgradeable for address;

    /// @custom:storage-location erc7201:story-protocol.linking-module.storage
    struct LinkingModuleStorage {
        mapping(bytes32 => bool) links;
        mapping(bytes32 => LinkConfig) linkConfigs;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.linking-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x9c884c7910549c48b2f059441cfee4a973c8102bda86741fa2535981e323cf9e;
    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    constructor(address _franchiseRegistry) {
        if (_franchiseRegistry == address(0)) revert ZeroAddress();
        FRANCHISE_REGISTRY = FranchiseRegistry(_franchiseRegistry);
        _disableInitializers();
    }

    function initialize(address accessControl) public initializer {
        __AccessControlledUpgradeable_init(accessControl);
    }

    function _getLinkingModuleStorage()
        private
        pure
        returns (LinkingModuleStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function link(LinkParams calldata params, bytes calldata data) external {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        LinkConfig storage config = $.linkConfigs[params.linkId];
        _verifyLinkParams(params, config);
        
        config.processor.processLink(params, data, msg.sender);

        $.links[_getLinkKey(params)] = true;
        emit Linked(params.sourceContract, params.sourceId, params.destContract, params.destId, params.linkId);
    }

    function unlink(LinkParams calldata params) external onlyRole(LINK_DISPUTER_ROLE) {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        bytes32 key = _getLinkKey(params);
        if (!$.links[key]) revert NonExistingLink();
        delete $.links[key];
        emit Unlinked(params.sourceContract, params.sourceId, params.destContract, params.destId, params.linkId);
    }

    function areTheyLinked(LinkParams calldata params) external view returns (bool) {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        return $.links[_getLinkKey(params)];
    }

    function _verifyLinkParams(LinkParams calldata params, LinkConfig memory config) private view {
        if (config.sourceIPAssetTypeMask == 0) revert NonExistingLink();
        (bool sourceResult, bool sourceIsAssetRegistry) = _checkLinkEnd(params.sourceContract, params.sourceId, config.sourceIPAssetTypeMask);
        if (!sourceResult) revert UnsupportedLinkSource();
        (bool destResult, bool destIsAssetRegistry) = _checkLinkEnd(params.destContract, params.destId, config.destIPAssetTypeMask);
        if (!destResult) revert UnsupportedLinkDestination();
        if(sourceIsAssetRegistry && destIsAssetRegistry && params.sourceContract != params.destContract && config.linkOnlySameFranchise) revert CannotLinkToAnotherFranchise();
    }

    function _isAssetRegistry(address ipAssetRegistry) internal virtual override view returns(bool) {
        try IIPAssetRegistry(ipAssetRegistry).franchiseId() returns (uint256 franchiseId) {
            return FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId) == ipAssetRegistry;
        } catch {
            return false;
        }
    }

    function _getLinkKey(LinkParams calldata params) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                params.sourceContract,
                params.sourceId,
                params.destContract,
                params.destId,
                params.linkId
            )
        );
    }

    /********* Setting Links *********/
    function setLinkConfig(bytes32 linkId, SetLinkParams calldata params) external onlyRole(LINK_MANAGER_ROLE) {
        if (!params.linkProcessor.supportsInterface(type(ILinkProcessor).interfaceId)) revert UnsupportedInterface("ILinkProcessor");
        LinkConfig memory config = LinkConfig(
            _convertToMask(params.sourceIPAssets, params.allowedExternalSource),
            _convertToMask(params.destIPAssets, params.allowedExternalDest),
            params.linkOnlySameFranchise,
            ILinkProcessor(params.linkProcessor)
        );
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        $.linkConfigs[linkId] = config;
        emit LinkConfigSet(
            linkId,
            config.sourceIPAssetTypeMask,
            config.destIPAssetTypeMask,
            config.linkOnlySameFranchise,
            params.linkProcessor
        );
    }

    function unsetLinkConfig(bytes32 linkId) external onlyRole(LINK_MANAGER_ROLE) {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        if (
            $.linkConfigs[linkId].sourceIPAssetTypeMask == 0
        ) revert NonExistingLink();
        delete $.linkConfigs[linkId];
        emit LinkConfigUnset(linkId);
    }

    function linkConfig(bytes32 linkId) external view returns (LinkConfig memory) {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        return $.linkConfigs[linkId];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}