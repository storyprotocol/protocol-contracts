// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ZeroAddress, UnsupportedInterface, Unauthorized } from "contracts/errors/General.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";
import { LibIPAssetId } from "contracts/ip-assets/LibIPAssetId.sol";
import { IRelationshipModule } from "./IRelationshipModule.sol";
import { LibIPAssetMask } from "./LibIPAssetMask.sol";
import { IRelationshipProcessor } from "./processors/IRelationshipProcessor.sol";
import { IPAsset, EXTERNAL_ASSET } from "contracts/IPAsset.sol";


/**
 * @title RelationshipModuleBase
 * @author Raul Martinez
 * @notice The relationship module is responsible for managing relationships between IP assets, and/or between them and external ERC721 contracts.
 * Relationships are defined by a relationship ID, which is a bytes32 value that represents a relationship type, for example (APPEARS_IN, CONTINUES_STORY, etc).
 * The meaning of each relationship may have different side effects in Story Protocol, which could other modules could react on, and even legal implications if
 * especified by the IPAsset licenses.
 * To be able to relate two elements, a RelationshipConfig must be set for the relationship ID, which defines the following:
 * - The IPAsset types that can be related as source and destination.
 * - The processor that will be called when a relationship is set, which can be used to perform additional checks or actions (checking ownership, asking for fees...).
 * - The disputer, which is the address that can unset a relationship.
 * - The time config, which defines the maximum and minimum TTL (time to live) for the relationship, and if it can be renewed. (maxTTL = 0 means no expiration)
 * - If the relationship can only be set between IPAssets of the same franchise, or it could link to IPAssets of other franchises.
 * 
 * It's up to subclasses to define which addresses can set relationship configs.
 */
abstract contract RelationshipModuleBase is IRelationshipModule, AccessControlledUpgradeable, Multicall {
    using ERC165CheckerUpgradeable for address;

    /// @custom:storage-location erc7201:story-protocol.relationship-module.storage
    struct RelationshipModuleStorage {
        mapping(bytes32 => bool) relationships;
        mapping(bytes32 => uint256) relationshipExpirations;
        mapping(bytes32 => RelationshipConfig) relConfigs;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.relationship-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0xd16687d5cf786234491b4cc484b2a64f24855aadee9b1b73824db1ed2840fd0b;
    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    /**
     * reverts if the TTL is not well configured for the relationship.
     * @param params the relationship params
     */
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

    /**
     * @notice Relates two IPAssets or an IPAsset and an external ERC721 contract.
     * To not revert, the params must be valid according to the relationship config, and the processor must not revert.
     * Processor can be used to perform additional checks or actions (checking ownership, asking for fees...).
     * Processors returning false imply that the relationship is pending (multi step process), and the relationship will not be set yet.
     * @param params the relationship params
     * @param data optional data that will be passed to the processor
     */
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

    /**
     * @notice Updates the end time of a relationship, if TimeConfig allows it.
     * @param relKey the relationship key, given by _getRelationshipKey(params)
     * @param timeConfig the relationship time config
     * @param ttl the new ttl
     * @return the new end time
     */
    function _updateEndTime(bytes32 relKey, TimeConfig memory timeConfig, uint256 ttl) private returns (uint256) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if (timeConfig.maxTTL != 0) {
            uint256 endTime = $.relationshipExpirations[relKey];
            if (endTime == 0 || timeConfig.renewable) {
                endTime = block.timestamp + ttl;
                $.relationshipExpirations[relKey] = endTime;
                return endTime;
            }
        }
        return 0;
    }

    /**
     * @notice Unrelates two IPAssets or an IPAsset and an external ERC721 contract.
     * Only callable by the disputer of the relationship, as defined in the relationship config.
     * @param params the relationship params
     */
    function unrelate(RelationshipParams calldata params) external {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if ($.relConfigs[params.relationshipId].disputer != msg.sender) revert Unauthorized();
        bytes32 key = _getRelationshipKey(params);
        if (!$.relationships[key]) revert NonExistingRelationship();
        delete $.relationships[key];
        emit RelationUnset(params.sourceContract, params.sourceId, params.destContract, params.destId, params.relationshipId);
    }

    /**
     * @notice Checks if two IPAssets or an IPAsset and an external ERC721 contract are related.
     * @param params the relationship params
     * @return true if they are related and the relationship has not expired, false otherwise
     */
    function areTheyRelated(RelationshipParams calldata params) external view returns (bool) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        return $.relationships[_getRelationshipKey(params)] && !isRelationshipExpired(params);
    }

    /**
     * @notice Checks if a relationship has expired.
     * @param params the relationship params
     * @return true if the relationship has expired, false if not expired or if it has no expiration
     */
    function isRelationshipExpired(RelationshipParams calldata params) public view returns (bool) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        uint256 endTime = $.relationshipExpirations[_getRelationshipKey(params)];
        return endTime != 0 && endTime < block.timestamp;
    }

    /**
     * @notice validates the relationship params according to the relationship config.
     * @param params the relationship params
     * @param relConfig the relationship config
     */
    function _verifyRelationshipParams(RelationshipParams calldata params, RelationshipConfig memory relConfig) private view {
        if (relConfig.sourceIPAssetTypeMask == 0) revert NonExistingRelationship();
        (bool sourceResult, bool sourceIsAssetRegistry) = _checkRelationshipNode(params.sourceContract, params.sourceId, relConfig.sourceIPAssetTypeMask);
        if (!sourceResult) revert UnsupportedRelationshipSrc();
        (bool destResult, bool destIsAssetRegistry) = _checkRelationshipNode(params.destContract, params.destId, relConfig.destIPAssetTypeMask);
        if (!destResult) revert UnsupportedRelationshipDst();
        if(sourceIsAssetRegistry && destIsAssetRegistry && params.sourceContract != params.destContract && relConfig.onlySameFranchise) revert CannotRelateToOtherFranchise();
    }


    /**
     * @dev Checks if the source or destination type of a relationship is allowed by the relationship config.
     * @param collection The address of the collection of the relationship endpoint
     * @param id The id of the relationship endpoint
     * @param assetTypeMask The asset type mask of the relationship config, which contains the allowed asset types and the external asset flag
     * @return result Whether the relationship endpoint is valid
     * @return isAssetRegistry Whether the relationship endpoint is a Story Protocol IP Asset Registry
     */
    function _checkRelationshipNode(address collection, uint256 id, uint256 assetTypeMask) private view returns (bool result, bool isAssetRegistry) {
        if (IERC721(collection).ownerOf(id) == address(0)) return (false, false);
        isAssetRegistry = FRANCHISE_REGISTRY.isIpAssetRegistry(collection);
        return (LibIPAssetMask._checkRelationshipNode(isAssetRegistry, id, assetTypeMask), isAssetRegistry);
    }

    /// calculates the relationship key by keccak256 hashing srcContract, srcId, dstContract, dstId and relationshipId
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

    /**
     * @notice Sets a relationship config for a relationship ID.
     * @param name the relationship name
     * @param params the relationship config params
     */
    function _setRelationshipConfig(string calldata name, SetRelationshipConfigParams calldata params) internal returns(bytes32 relationshipId) {
        relationshipId = getRelationshipId(name);
        RelationshipConfig memory relConfig = _convertRelParams(params);
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        $.relConfigs[relationshipId] = relConfig;
        emit RelationshipConfigSet(
            name,
            relationshipId,
            relConfig.sourceIPAssetTypeMask,
            relConfig.destIPAssetTypeMask,
            relConfig.onlySameFranchise,
            params.processor,
            relConfig.timeConfig.maxTTL,
            relConfig.timeConfig.minTTL,
            relConfig.timeConfig.renewable
        );
        return relationshipId;
    }

    /**
     * @notice Unsets a relationship config for a relationship ID, reverts if it doesn't exist.
     * @param relationshipId the relationship ID
     */
    function _unsetRelationshipConfig(bytes32 relationshipId) internal {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if (
            $.relConfigs[relationshipId].sourceIPAssetTypeMask == 0
        ) revert NonExistingRelationship();
        delete $.relConfigs[relationshipId];
        emit RelationshipConfigUnset(relationshipId);
    }

    /**
     * @notice Converts the SetRelationshipConfigParams to a RelationshipConfig after validating them.
     * @dev reverts if
     * - the processor doesn't support IRelationshipProcessor interface
     * - the TTL is not well configured.
     * - the disputer is the zero address
     * 
     * @param params the SetRelationshipConfigParams
     * @return the RelationshipConfig
     */
    function _convertRelParams(SetRelationshipConfigParams calldata params) private view returns(RelationshipConfig memory) {
        if (!params.processor.supportsInterface(type(IRelationshipProcessor).interfaceId)) revert UnsupportedInterface("IRelationshipProcessor");
        if (params.timeConfig.maxTTL < params.timeConfig.minTTL) revert InvalidTTL();
        if (params.disputer == address(0)) revert ZeroAddress();
        return RelationshipConfig(
            LibIPAssetMask._convertToMask(params.sourceIPAssets, params.allowedExternalSource),
            LibIPAssetMask._convertToMask(params.destIPAssets, params.allowedExternalDest),
            params.onlySameFranchise,
            IRelationshipProcessor(params.processor),
            params.disputer,
            params.timeConfig
        );
    }

    /// returns a RelationshipConfig for the given relationshipId, or an empty one if it doesn't exist
    function getRelationshipConfig(bytes32 relationshipId) public view returns (RelationshipConfig memory) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        return $.relConfigs[relationshipId];
    }

    /**
     * @dev convenience method to return a SetRelationshipConfigParams from a relationshipId, or an empty one if it doesn't exist
     * NOTE: Caller must ignore the array elements of value 0 in the IPAsset arrays
     * @param relationshipId the relationship ID
     * @return params the SetRelationshipConfigParams
     */ 
    function getRelationshipConfigDecoded(bytes32 relationshipId) external view returns(SetRelationshipConfigParams memory) {
        RelationshipConfig memory relConfig = getRelationshipConfig(relationshipId);
        (IPAsset[] memory sourceIPAssets, bool sourceSupportsExternal) = LibIPAssetMask._convertFromMask(relConfig.sourceIPAssetTypeMask);
        (IPAsset[] memory destIPAssets, bool destSupportsExternal) = LibIPAssetMask._convertFromMask(relConfig.destIPAssetTypeMask);
        return SetRelationshipConfigParams(
            sourceIPAssets,
            sourceSupportsExternal,
            destIPAssets,
            destSupportsExternal,
            relConfig.onlySameFranchise,
            address(relConfig.processor),
            relConfig.disputer,
            relConfig.timeConfig
        );
    }

    function getRelationshipId(string calldata name) public pure returns (bytes32) {
        return keccak256(abi.encode(name));
    }
    

    /********* Mask Helpers *********/
    /**
     * @dev converts an array of IPAssets types and the allows external flag to a mask, by setting the bits corresponding
     * to the uint8 equivalent of the IPAsset types to 1.
     * @param ipAssets The array of IPAsset types
     * @param allowsExternal Whether the relationship config allows external (non SP ERC721) assets
     * @return mask The mask representing the IPAsset types and the allows external flag
     */
    function convertToMask(IPAsset[] calldata ipAssets, bool allowsExternal) external pure returns (uint256) {
        return LibIPAssetMask._convertToMask(ipAssets, allowsExternal);
    }

    /**
     * @dev converts a mask to an array of IPAsset types and the allows external flag, by checking the bits corresponding
     * to the uint8 equivalent of the IPAsset types.
     * @param mask The mask representing the IPAsset types and the allows external flag
     * @return ipAssets The array of IPAsset types
     * @return allowsExternal Whether the relationship config allows external (non SP ERC721) assets
     */
    function convertFromMask(uint256 mask) external pure returns (IPAsset[] memory ipAssets, bool allowsExternal) {
        return LibIPAssetMask._convertFromMask(mask);
    }

    /// returns true if the asset type is supported by the mask, false otherwise
    function supportsIPAssetType(uint256 mask, uint8 assetType) external pure returns (bool) {
        return LibIPAssetMask._supportsIPAssetType(mask, assetType);
    }

}