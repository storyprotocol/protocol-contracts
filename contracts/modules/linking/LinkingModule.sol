// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ZeroAddress } from "contracts/errors/General.sol";
import { UPGRADER_ROLE, LINK_MANAGER_ROLE, LINK_DISPUTER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { IPAsset } from "contracts/IPAsset.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";
import { LinkIPAssetTypeChecker } from "./LinkIPAssetTypeChecker.sol";
import "forge-std/console.sol";

contract LinkingModule is AccessControlledUpgradeable, LinkIPAssetTypeChecker {
    event Linked(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 linkId
    );
    event Unlinked(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 linkId
    );

    event ProtocolLinkSet(
        bytes32 linkId,
        uint256 sourceIPAssetTypeMask,
        uint256 destIPAssetTypeMask,
        bool linkOnlySameFranchise
    );
    event ProtocolLinkUnset(bytes32 linkId);

    error NonExistingLink();
    error IntentAlreadyRegistered();
    error UnsupportedLinkSource();
    error UnsupportedLinkDestination();
    error CannotLinkToAnotherFranchise();

    struct LinkConfig {
        uint256 sourceIPAssetTypeMask;
        uint256 destIPAssetTypeMask;
        bool linkOnlySameFranchise;
    }

    struct SetLinkParams {
        IPAsset[] sourceIPAssets;
        bool allowedExternalSource;
        IPAsset[] destIPAssets;
        bool allowedExternalDest;
        bool linkOnlySameFranchise;
    }

    /// @custom:storage-location erc7201:story-protocol.linking-module.storage
    struct LinkingModuleStorage {
        mapping(bytes32 => bool) links;
        mapping(bytes32 => LinkConfig) protocolLinks;
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

    function link(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 linkId
    ) external {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        LinkConfig storage config = $.protocolLinks[linkId];
        if (config.sourceIPAssetTypeMask == 0) revert NonExistingLink();
        (bool sourceResult, bool sourceIsAssetRegistry) = _checkLinkEnd(sourceContract, sourceId, config.sourceIPAssetTypeMask);
        if (!sourceResult) revert UnsupportedLinkSource();
        (bool destResult, bool destIsAssetRegistry) = _checkLinkEnd(destContract, destId, config.destIPAssetTypeMask);
        if (!destResult) revert UnsupportedLinkDestination();
        if(sourceIsAssetRegistry && destIsAssetRegistry && sourceContract != destContract && config.linkOnlySameFranchise) revert CannotLinkToAnotherFranchise();
        $.links[
            keccak256(
                abi.encode(
                    sourceContract,
                    sourceId,
                    destContract,
                    destId,
                    linkId
                )
            )
        ] = true;
        emit Linked(sourceContract, sourceId, destContract, destId, linkId);
    }

    function unlink(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 linkId
    ) external onlyRole(LINK_DISPUTER_ROLE) {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        bytes32 key = keccak256(
            abi.encode(sourceContract, sourceId, destContract, destId, linkId)
        );
        if (!$.links[key]) revert NonExistingLink();
        delete $.links[key];
        emit Unlinked(sourceContract, sourceId, destContract, destId, linkId);
    }

    function areTheyLinked(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 linkId
    ) external view returns (bool) {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        return
            $.links[
                keccak256(
                    abi.encode(
                        sourceContract,
                        sourceId,
                        destContract,
                        destId,
                        linkId
                    )
                )
            ];
    }

    function _isAssetRegistry(address ipAssetRegistry) internal virtual override view returns(bool) {
        try IIPAssetRegistry(ipAssetRegistry).franchiseId() returns (uint256 franchiseId) {
            return FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId) == ipAssetRegistry;
        } catch {
            return false;
        }
    }

    /********* Setting Links *********/
    function setProtocolLink(
        bytes32 linkId,
        SetLinkParams calldata params
    ) external onlyRole(LINK_MANAGER_ROLE) {
        LinkConfig memory config = LinkConfig(
            _convertToMask(params.sourceIPAssets, params.allowedExternalSource),
            _convertToMask(params.destIPAssets, params.allowedExternalDest),
            params.linkOnlySameFranchise
        );
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        $.protocolLinks[linkId] = config;
        emit ProtocolLinkSet(
            linkId,
            config.sourceIPAssetTypeMask,
            config.destIPAssetTypeMask,
            config.linkOnlySameFranchise
        );
    }

    function unsetProtocolLink(
        bytes32 linkId
    ) external onlyRole(LINK_MANAGER_ROLE) {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        if (
            $.protocolLinks[linkId].sourceIPAssetTypeMask == 0
        ) revert NonExistingLink();
        delete $.protocolLinks[linkId];
        emit ProtocolLinkUnset(linkId);
    }

    function protocolLinks(bytes32 linkId) external view returns (LinkConfig memory) {
        LinkingModuleStorage storage $ = _getLinkingModuleStorage();
        return $.protocolLinks[linkId];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}