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

    event AddedProtocolLink(
        bytes32 linkId,
        uint256 sourceIPAssetTypeMask,
        uint256 destIPAssetTypeMask,
        bool linkOnlySameFranchise
    );
    event RemovedProtocolLink(bytes32 linkId);

    error NonExistingLink();
    error IntentAlreadyRegistered();
    error UndefinedLink();
    error UnsupportedLinkSource();
    error UnsupportedLinkDestination();

    struct LinkConfig {
        uint256 sourceIPAssetTypeMask;
        uint256 destIPAssetTypeMask;
        bool linkOnlySameFranchise;
    }

    struct AddLinkParams {
        IPAsset[] sourceIPAssets;
        bool allowedExternalSource;
        IPAsset[] destIPAssets;
        bool allowedExternalDest;
        bool linkOnlySameFranchise;
    }

    mapping(bytes32 => bool) public links;
    mapping(bytes32 => LinkConfig) public protocolLinks;

    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    constructor(address _franchiseRegistry) {
        if (_franchiseRegistry == address(0)) revert ZeroAddress();
        FRANCHISE_REGISTRY = FranchiseRegistry(_franchiseRegistry);
        _disableInitializers();
    }

    function initialize(address accessControl) public initializer {
        __AccessControlledUpgradeable_init(accessControl);
    }

    function link(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 linkId
    ) external {
        LinkConfig storage config = protocolLinks[linkId];
        if (_checkLinkEnd(
                sourceContract,
                sourceId,
                config.sourceIPAssetTypeMask
        )) revert UnsupportedLinkSource();
        if (_checkLinkEnd(destContract, destId, config.destIPAssetTypeMask))
            revert UnsupportedLinkDestination();
        links[
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
        bytes32 key = keccak256(
            abi.encode(sourceContract, sourceId, destContract, destId, linkId)
        );
        if (!links[key]) revert NonExistingLink();
        delete links[key];
        emit Unlinked(sourceContract, sourceId, destContract, destId, linkId);
    }

    function areTheyLinked(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 linkId
    ) external view returns (bool) {
        return
            links[
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
        uint256 franchiseId = IIPAssetRegistry(ipAssetRegistry).franchiseId();
        return FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId) != ipAssetRegistry;
    }

    /********* Protocol level linkIds *********/
    function addProtocolLink(
        bytes32 linkId,
        AddLinkParams calldata params
    ) external onlyRole(LINK_MANAGER_ROLE) {
        LinkConfig memory config = LinkConfig(
            _convertToMask(params.sourceIPAssets, params.allowedExternalSource),
            _convertToMask(params.destIPAssets, params.allowedExternalDest),
            params.linkOnlySameFranchise
        );
        protocolLinks[linkId] = config;
        emit AddedProtocolLink(
            linkId,
            config.sourceIPAssetTypeMask,
            config.destIPAssetTypeMask,
            config.linkOnlySameFranchise
        );
    }

    function removeProtocolLink(
        bytes32 linkId
    ) external onlyRole(LINK_MANAGER_ROLE) {
        if (
            protocolLinks[linkId].sourceIPAssetTypeMask == 0 &&
            protocolLinks[linkId].destIPAssetTypeMask == 0
        ) revert UndefinedLink();
        delete protocolLinks[linkId];
        emit RemovedProtocolLink(linkId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}