// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ZeroAddress, UnsupportedInterface, Unauthorized } from "contracts/errors/General.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";
import { RelationshipTypeChecker } from "./RelationshipTypeChecker.sol";
import { IRelationshipModule } from "./IRelationshipModule.sol";
import { IRelationshipProcessor } from "./RelationshipProcessors/IRelationshipProcessor.sol";


abstract contract RelationshipModuleBase is IRelationshipModule, AccessControlledUpgradeable, RelationshipTypeChecker, Multicall {
    using ERC165CheckerUpgradeable for address;

    /// @custom:storage-location erc7201:story-protocol.relationship-module.storage
    struct RelationshipModuleStorage {
        mapping(bytes32 => bool) relationships;
        mapping(bytes32 => uint256) relationshipEnds;
        mapping(bytes32 => RelationshipConfig) relConfigs;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.relationship-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0xd16687d5cf786234491b4cc484b2a64f24855aadee9b1b73824db1ed2840fd0b;
    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    modifier onlyValidTTL(RelationshipParams calldata params) {
        RelationshipConfig storage relConfig = _getRelationshipModuleStorage().relConfigs[params.relationshipId];
        if (relConfig.timeConfig.maxTTL != 0 && params.ttl != 0) {
            if (params.ttl > relConfig.timeConfig.maxTTL || params.ttl < relConfig.timeConfig.minTTL) revert InvalidEndTimestamp();
        }
        _;
    }

    constructor(address _franchiseRegistry) {
        if (_franchiseRegistry == address(0)) revert ZeroAddress();
        FRANCHISE_REGISTRY = FranchiseRegistry(_franchiseRegistry);
        _disableInitializers();
    }

    function __RelationshipModuleBase_init(address accessControl) public initializer {
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

    function relate(RelationshipParams calldata params, bytes calldata data) external onlyValidTTL(params) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        RelationshipConfig storage relConfig = $.relConfigs[params.relationshipId];
        _verifyRelationshipParams(params, relConfig);
        
        if (!relConfig.processor.processRelationship(params, data, msg.sender)) {
            emit RelationPendingProcessor(params.sourceContract, params.sourceId, params.destContract, params.destId, params.relationshipId);
        } else {
            bytes32 relKey = _getRelationshipKey(params);
            $.relationships[relKey] = true;
            uint256 endTime = _updateEndTime(relKey, relConfig.timeConfig, params.ttl);
            emit RelationSet(params.sourceContract, params.sourceId, params.destContract, params.destId, params.relationshipId, endTime);
        }
    }

    function _updateEndTime(bytes32 relKey, TimeConfig memory timeConfig, uint256 ttl) private returns (uint256) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if (timeConfig.maxTTL != 0) {
            uint256 endTime = $.relationshipEnds[relKey];
            if (endTime == 0 || timeConfig.renewable) {
                endTime = block.timestamp + ttl;
                $.relationshipEnds[relKey] = endTime;
                return endTime;
            }
        }
        return 0;
    }

    function unrelate(RelationshipParams calldata params) external {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if ($.relConfigs[params.relationshipId].disputer != msg.sender) revert Unauthorized();
        bytes32 key = _getRelationshipKey(params);
        if (!$.relationships[key]) revert NonExistingRelationship();
        delete $.relationships[key];
        emit RelationUnset(params.sourceContract, params.sourceId, params.destContract, params.destId, params.relationshipId);
    }

    function areTheyRelated(RelationshipParams calldata params) external view returns (bool) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        return $.relationships[_getRelationshipKey(params)] && !isLinkExpired(params);
    }

    function isLinkExpired(RelationshipParams calldata params) public view returns (bool) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        uint256 endTime = $.relationshipEnds[_getRelationshipKey(params)];
        return endTime != 0 && endTime < block.timestamp;
    }

    function _verifyRelationshipParams(RelationshipParams calldata params, RelationshipConfig memory relConfig) private view {
        if (relConfig.sourceIPAssetTypeMask == 0) revert NonExistingRelationship();
        (bool sourceResult, bool sourceIsAssetRegistry) = _checkRelationshipNode(params.sourceContract, params.sourceId, relConfig.sourceIPAssetTypeMask);
        if (!sourceResult) revert UnsupportedRelationshipSource();
        (bool destResult, bool destIsAssetRegistry) = _checkRelationshipNode(params.destContract, params.destId, relConfig.destIPAssetTypeMask);
        if (!destResult) revert UnsupportedRelationshipDestination();
        if(sourceIsAssetRegistry && destIsAssetRegistry && params.sourceContract != params.destContract && relConfig.onlySameFranchise) revert CannotRelationshipToAnotherFranchise();
    }

    function _isAssetRegistry(address ipAssetRegistry) internal virtual override view returns(bool) {
        try IIPAssetRegistry(ipAssetRegistry).franchiseId() returns (uint256 franchiseId) {
            return FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId) == ipAssetRegistry;
        } catch {
            return false;
        }
    }

    function _getRelationshipKey(RelationshipParams calldata params) internal pure returns (bytes32) {
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
    function _setRelationshipConfig(bytes32 relationshipId, SetRelationshipConfigParams calldata params) internal {
        RelationshipConfig memory relConfig = _convertRelParams(params);
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        $.relConfigs[relationshipId] = relConfig;
        emit RelationshipConfigSet(
            relationshipId,
            relConfig.sourceIPAssetTypeMask,
            relConfig.destIPAssetTypeMask,
            relConfig.onlySameFranchise,
            params.processor,
            relConfig.timeConfig.maxTTL,
            relConfig.timeConfig.minTTL
        );
    }

    function _unsetRelationshipConfig(bytes32 relationshipId) internal {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if (
            $.relConfigs[relationshipId].sourceIPAssetTypeMask == 0
        ) revert NonExistingRelationship();
        delete $.relConfigs[relationshipId];
        emit RelationshipConfigUnset(relationshipId);
    }

    function _convertRelParams(SetRelationshipConfigParams calldata params) private view returns(RelationshipConfig memory) {
        if (!params.processor.supportsInterface(type(IRelationshipProcessor).interfaceId)) revert UnsupportedInterface("IRelationshipProcessor");
        if (params.timeConfig.maxTTL < params.timeConfig.minTTL) revert InvalidTTL();
        if (params.disputer == address(0)) revert ZeroAddress();
        return RelationshipConfig(
            _convertToMask(params.sourceIPAssets, params.allowedExternalSource),
            _convertToMask(params.destIPAssets, params.allowedExternalDest),
            params.onlySameFranchise,
            IRelationshipProcessor(params.processor),
            params.disputer,
            params.timeConfig
        );
    }

    function relationshipConfig(bytes32 relationshipId) external view returns (RelationshipConfig memory) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        return $.relConfigs[relationshipId];
    }

}