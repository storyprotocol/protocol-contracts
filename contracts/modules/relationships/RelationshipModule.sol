// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ZeroAddress, UnsupportedInterface } from "contracts/errors/General.sol";
import { UPGRADER_ROLE, RELATIONSHIP_MANAGER_ROLE, RELATIONSHIP_DISPUTER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";
import { RelationshipTypeChecker } from "./RelationshipTypeChecker.sol";
import { IRelationshipModule } from "./IRelationshipModule.sol";
import { IRelationshipProcessor } from "./RelationshipProcessors/IRelationshipProcessor.sol";

contract RelationshipModule is IRelationshipModule, AccessControlledUpgradeable, RelationshipTypeChecker {
    using ERC165CheckerUpgradeable for address;

    /// @custom:storage-location erc7201:story-protocol.relationship-module.storage
    struct RelationshipModuleStorage {
        mapping(bytes32 => bool) relationships;
        mapping(bytes32 => RelationshipConfig) relConfigs;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.relationship-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0xd16687d5cf786234491b4cc484b2a64f24855aadee9b1b73824db1ed2840fd0b;
    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    constructor(address _franchiseRegistry) {
        if (_franchiseRegistry == address(0)) revert ZeroAddress();
        FRANCHISE_REGISTRY = FranchiseRegistry(_franchiseRegistry);
        _disableInitializers();
    }

    function initialize(address accessControl) public initializer {
        __AccessControlledUpgradeable_init(accessControl);
    }

    function _getRelationshipModuleStorage()
        private
        pure
        returns (RelationshipModuleStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function relate(RelationshipParams calldata params, bytes calldata data) external {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        RelationshipConfig storage config = $.relConfigs[params.relationshipId];
        _verifyRelationshipParams(params, config);
        
        config.processor.processRelationship(params, data, msg.sender);

        $.relationships[_getRelationshipKey(params)] = true;
        emit RelationSet(params.sourceContract, params.sourceId, params.destContract, params.destId, params.relationshipId);
    }

    function unrelate(RelationshipParams calldata params) external onlyRole(RELATIONSHIP_DISPUTER_ROLE) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        bytes32 key = _getRelationshipKey(params);
        if (!$.relationships[key]) revert NonExistingRelationship();
        delete $.relationships[key];
        emit RelationUnset(params.sourceContract, params.sourceId, params.destContract, params.destId, params.relationshipId);
    }

    function areTheyRelated(RelationshipParams calldata params) external view returns (bool) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        return $.relationships[_getRelationshipKey(params)];
    }

    function _verifyRelationshipParams(RelationshipParams calldata params, RelationshipConfig memory config) private view {
        if (config.sourceIPAssetTypeMask == 0) revert NonExistingRelationship();
        (bool sourceResult, bool sourceIsAssetRegistry) = _checkRelationshipNode(params.sourceContract, params.sourceId, config.sourceIPAssetTypeMask);
        if (!sourceResult) revert UnsupportedRelationshipSource();
        (bool destResult, bool destIsAssetRegistry) = _checkRelationshipNode(params.destContract, params.destId, config.destIPAssetTypeMask);
        if (!destResult) revert UnsupportedRelationshipDestination();
        if(sourceIsAssetRegistry && destIsAssetRegistry && params.sourceContract != params.destContract && config.onlySameFranchise) revert CannotRelationshipToAnotherFranchise();
    }

    function _isAssetRegistry(address ipAssetRegistry) internal virtual override view returns(bool) {
        try IIPAssetRegistry(ipAssetRegistry).franchiseId() returns (uint256 franchiseId) {
            return FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId) == ipAssetRegistry;
        } catch {
            return false;
        }
    }

    function _getRelationshipKey(RelationshipParams calldata params) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                params.sourceContract,
                params.sourceId,
                params.destContract,
                params.destId,
                params.relationshipId
            )
        );
    }

    /********* Setting Relationships *********/
    function setRelationshipConfig(bytes32 relationshipId, SetRelationshipParams calldata params) external onlyRole(RELATIONSHIP_MANAGER_ROLE) {
        if (!params.processor.supportsInterface(type(IRelationshipProcessor).interfaceId)) revert UnsupportedInterface("IRelationshipProcessor");
        RelationshipConfig memory config = RelationshipConfig(
            _convertToMask(params.sourceIPAssets, params.allowedExternalSource),
            _convertToMask(params.destIPAssets, params.allowedExternalDest),
            params.onlySameFranchise,
            IRelationshipProcessor(params.processor)
        );
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        $.relConfigs[relationshipId] = config;
        emit RelationshipConfigSet(
            relationshipId,
            config.sourceIPAssetTypeMask,
            config.destIPAssetTypeMask,
            config.onlySameFranchise,
            params.processor
        );
    }

    function unsetConfig(bytes32 relationshipId) external onlyRole(RELATIONSHIP_MANAGER_ROLE) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if (
            $.relConfigs[relationshipId].sourceIPAssetTypeMask == 0
        ) revert NonExistingRelationship();
        delete $.relConfigs[relationshipId];
        emit RelationshipConfigUnset(relationshipId);
    }

    function config(bytes32 relationshipId) external view returns (RelationshipConfig memory) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        return $.relConfigs[relationshipId];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}