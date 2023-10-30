// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ZeroAddress, UnsupportedInterface, Unauthorized } from "contracts/errors/General.sol";
import { IPAssetOrgFactory } from "contracts/IPAssetOrgFactory.sol";
import { IIPAssetOrg } from "contracts/interfaces/ip-assets/IIPAssetOrg.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { LibIPAssetMask } from "./LibIPAssetMask.sol";
import { IRelationshipModule } from "contracts/interfaces/modules/relationships/IRelationshipModule.sol";
import { IRelationshipProcessor } from "contracts/interfaces/modules/relationships/processors/IRelationshipProcessor.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";

/// @title RelationshipModuleBase
/// @author Raul Martinez
/// @notice The relationship module is responsible for managing relationships between IP assets, and/or between them and external ERC721 contracts.
/// Relationships are defined by a relationship ID, which is a bytes32 value that represents a relationship type, for example (APPEARS_IN, CONTINUES_STORY, etc).
/// The meaning of each relationship may have different side effects in Story Protocol, which could other modules could react on, and even legal implications if
/// especified by the IPAsset licenses.
/// To be able to relate two elements, a RelationshipConfig must be set for the relationship ID, which defines the following:
/// - The IPAsset types that can be related as source and destination.
/// - The processor that will be called when a relationship is set, which can be used to perform additional checks or actions (checking ownership, asking for fees...).
/// - The disputer, which is the address that can unset a relationship.
/// - The time config, which defines the maximum and minimum TTL (time to live) for the relationship, and if it can be renewed. (maxTtl = 0 means no expiration)
/// - If the relationship can only be set between IPAssets of the same franchise, or it could link to IPAssets of other franchises.
/// 
/// It's up to subclasses to define which addresses can set relationship configs.
abstract contract RelationshipModuleBase is IRelationshipModule, AccessControlledUpgradeable, Multicall {
    using ERC165CheckerUpgradeable for address;

    /// @custom:storage-location erc7201:story-protocol.relationship-module.storage
    struct RelationshipModuleStorage {
        mapping(bytes32 => bool) relationships;
        mapping(bytes32 => uint256) relationshipExpirations;
        mapping(bytes32 => Relationship.RelationshipConfig) relConfigs;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.relationship-module.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0xd16687d5cf786234491b4cc484b2a64f24855aadee9b1b73824db1ed2840fd0b;
    IPAssetOrgFactory public immutable IP_ASSET_ORG_FACTORY;

    
    /// reverts if the TTL is not well configured for the relationship.
    /// @param params_ the relationship params
    modifier onlyValidTTL(Relationship.RelationshipParams calldata params_) {
        Relationship.RelationshipConfig storage relConfig = _getRelationshipModuleStorage().relConfigs[params_.relationshipId];
        if (relConfig.timeConfig.maxTtl != 0 && params_.ttl != 0) {
            if (params_.ttl > relConfig.timeConfig.maxTtl || params_.ttl < relConfig.timeConfig.minTtl) revert Errors.RelationshipModule_InvalidEndTimestamp();
        }
        _;
    }

    constructor(address ipAssetOrgFactory_) {
        if (ipAssetOrgFactory_ == address(0)) revert Errors.ZeroAddress();
        IP_ASSET_ORG_FACTORY = IPAssetOrgFactory(ipAssetOrgFactory_);
        _disableInitializers();
    }

    /// @notice Relates two IPAssets or an IPAsset and an external ERC721 contract.
    /// To not revert, the params must be valid according to the relationship config, and the processor must not revert.
    /// Processor can be used to perform additional checks or actions (checking ownership, asking for fees...).
    /// Processors returning false imply that the relationship is pending (multi step process), and the relationship will not be set yet.
    /// @param params_ the relationship params
    /// @param data_ optional data that will be passed to the processor
    function relate(Relationship.RelationshipParams calldata params_, bytes calldata data_) external onlyValidTTL(params_) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        Relationship.RelationshipConfig storage relConfig = $.relConfigs[params_.relationshipId];
        _verifyRelationshipParams(params_, relConfig);

        if (!relConfig.processor.processRelationship(params_, data_, msg.sender)) {
            emit RelationPendingProcessor(params_.sourceContract, params_.sourceId, params_.destContract, params_.destId, params_.relationshipId);
        } else {
            bytes32 relKey = getRelationshipKey(params_);
            $.relationships[relKey] = true;
            uint256 endTime = _updateEndTime(relKey, relConfig.timeConfig, params_.ttl);
            emit RelationSet(params_.sourceContract, params_.sourceId, params_.destContract, params_.destId, params_.relationshipId, endTime);
        }
    }

    /// @notice Unrelates two IPAssets or an IPAsset and an external ERC721 contract.
    /// Only callable by the disputer of the relationship, as defined in the relationship config.
    /// @param params_ the relationship params
    function unrelate(Relationship.RelationshipParams calldata params_) external {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if ($.relConfigs[params_.relationshipId].disputer != msg.sender) revert Errors.Unauthorized();
        bytes32 key = getRelationshipKey(params_);
        if (!$.relationships[key]) revert Errors.RelationshipModule_NonExistingRelationship();
        delete $.relationships[key];
        emit RelationUnset(params_.sourceContract, params_.sourceId, params_.destContract, params_.destId, params_.relationshipId);
    }


    /// @notice Checks if two IPAssets or an IPAsset and an external ERC721 contract are related.
    /// @param params_ the relationship params
    /// @return true if they are related and the relationship has not expired, false otherwise
    function areTheyRelated(Relationship.RelationshipParams calldata params_) external view returns (bool) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        return $.relationships[getRelationshipKey(params_)] && !isRelationshipExpired(params_);
    }

    /// @dev convenience method to return a SetRelationshipConfigParams from a relationshipId, or an empty one if it doesn't exist
    /// NOTE: Caller must ignore the array elements of value 0 in the IPAsset arrays
    /// @param relationshipId_ the relationship ID
    function getRelationshipConfigDecoded(bytes32 relationshipId_) external view returns(Relationship.SetRelationshipConfigParams memory) {
        Relationship.RelationshipConfig memory relConfig = getRelationshipConfig(relationshipId_);
        (IPAsset.IPAssetType[] memory sourceIpAssets, bool sourceSupportsExternal) = LibIPAssetMask._convertFromMask(relConfig.sourceIpAssetTypeMask);
        (IPAsset.IPAssetType[] memory destIpAssets, bool destSupportsExternal) = LibIPAssetMask._convertFromMask(relConfig.destIpAssetTypeMask);
        return Relationship.SetRelationshipConfigParams(
            sourceIpAssets,
            sourceSupportsExternal,
            destIpAssets,
            destSupportsExternal,
            relConfig.onlySameIPAssetOrg,
            address(relConfig.processor),
            relConfig.disputer,
            relConfig.timeConfig
        );
    }

    /********* Mask Helpers *********/

    /// @dev converts an array of IPAssets types and the allows external flag to a mask, by setting the bits corresponding
    /// to the uint8 equivalent of the IPAsset types to 1.
    /// @param ipAssets_ The array of IPAsset types
    /// @param allowsExternal_ Whether the relationship config allows external (non SP ERC721) assets
    /// @return mask The mask representing the IPAsset types and the allows external flag
    function convertToMask(IPAsset.IPAssetType[] calldata ipAssets_, bool allowsExternal_) external pure returns (uint256) {
        return LibIPAssetMask._convertToMask(ipAssets_, allowsExternal_);
    }

    /// @dev converts a mask to an array of IPAsset types and the allows external flag, by checking the bits corresponding
    /// to the uint8 equivalent of the IPAsset types.
    /// @param mask_ The mask representing the IPAsset types and the allows external flag
    /// @return ipAssets The array of IPAsset types
    /// @return allowsExternal Whether the relationship config allows external (non SP ERC721) assets
    function convertFromMask(uint256 mask_) external pure returns (IPAsset.IPAssetType[] memory ipAssets, bool allowsExternal) {
        return LibIPAssetMask._convertFromMask(mask_);
    }

    /// returns true if the asset type is supported by the mask, false otherwise
    function supportsIPAssetType(uint256 mask_, uint8 assetType_) external pure returns (bool) {
        return LibIPAssetMask._supportsIPAssetType(mask_, assetType_);
    }

    function __RelationshipModuleBase_init(address accessControl_) public initializer {
        __AccessControlledUpgradeable_init(accessControl_);
    }

    /// @notice Checks if a relationship has expired.
    /// @param params_ the relationship params
    /// @return true if the relationship has expired, false if not expired or if it has no expiration
    function isRelationshipExpired(Relationship.RelationshipParams calldata params_) public view returns (bool) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        uint256 endTime = $.relationshipExpirations[getRelationshipKey(params_)];
        return endTime != 0 && endTime < block.timestamp;
    }

    /// returns a RelationshipConfig for the given relationshipId, or an empty one if it doesn't exist
    function getRelationshipConfig(bytes32 relationshipId_) public view returns (Relationship.RelationshipConfig memory) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        return $.relConfigs[relationshipId_];
    }

    function getRelationshipId(string calldata name_) public pure returns (bytes32) {
        return keccak256(abi.encode(name_));
    }

    /// calculates the relationship key by keccak256 hashing srcContract, srcId, dstContract, dstId and relationshipId
    function getRelationshipKey(Relationship.RelationshipParams calldata params_) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                params_.sourceContract,
                params_.sourceId,
                params_.destContract,
                params_.destId,
                params_.relationshipId
            )
        );
    }

    /********* Setting Relationships *********/


    /// @notice Sets a relationship config for a relationship ID.
    /// @param name_ the relationship name
    /// @param params_ the relationship config params
    function _setRelationshipConfig(string calldata name_, Relationship.SetRelationshipConfigParams calldata params_) internal returns(bytes32 relationshipId) {
        relationshipId = getRelationshipId(name_);
        Relationship.RelationshipConfig memory relConfig = _convertRelParams(params_);
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        $.relConfigs[relationshipId] = relConfig;
        emit RelationshipConfigSet(
            name_,
            relationshipId,
            relConfig.sourceIpAssetTypeMask,
            relConfig.destIpAssetTypeMask,
            relConfig.onlySameIPAssetOrg,
            params_.processor,
            relConfig.timeConfig.maxTtl,
            relConfig.timeConfig.minTtl,
            relConfig.timeConfig.renewable
        );
        return relationshipId;
    }

    /// @notice Unsets a relationship config for a relationship ID, reverts if it doesn't exist.
    /// @param relationshipId_ the relationship ID
    function _unsetRelationshipConfig(bytes32 relationshipId_) internal {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if (
            $.relConfigs[relationshipId_].sourceIpAssetTypeMask == 0
        ) revert Errors.RelationshipModule_NonExistingRelationship();
        delete $.relConfigs[relationshipId_];
        emit RelationshipConfigUnset(relationshipId_);
    }

    /// @notice Updates the end time of a relationship, if TimeConfig allows it.
    /// @param relKey_ the relationship key, given by getRelationshipKey(params)
    /// @param timeConfig_ the relationship time config
    /// @param ttl_ the new ttl
    /// @return the new end time
    function _updateEndTime(bytes32 relKey_, Relationship.TimeConfig memory timeConfig_, uint256 ttl_) private returns (uint256) {
        RelationshipModuleStorage storage $ = _getRelationshipModuleStorage();
        if (timeConfig_.maxTtl != 0) {
            uint256 endTime = $.relationshipExpirations[relKey_];
            if (endTime == 0 || timeConfig_.renewable) {
                endTime = block.timestamp + ttl_;
                $.relationshipExpirations[relKey_] = endTime;
                return endTime;
            }
        }
        return 0;
    }

    /// @notice validates the relationship params according to the relationship config.
    /// @param params_ the relationship params
    /// @param relConfig_ the relationship config
    function _verifyRelationshipParams(Relationship.RelationshipParams calldata params_, Relationship.RelationshipConfig memory relConfig_) private view {
        if (relConfig_.sourceIpAssetTypeMask == 0) revert Errors.RelationshipModule_NonExistingRelationship();
        (bool sourceResult, bool sourceIsAssetRegistry) = _checkRelationshipNode(params_.sourceContract, params_.sourceId, relConfig_.sourceIpAssetTypeMask);
        if (!sourceResult) revert Errors.RelationshipModule_UnsupportedRelationshipSrc();
        (bool destResult, bool destIsAssetRegistry) = _checkRelationshipNode(params_.destContract, params_.destId, relConfig_.destIpAssetTypeMask);
        if (!destResult) revert Errors.RelationshipModule_UnsupportedRelationshipDst();
        if(sourceIsAssetRegistry && destIsAssetRegistry && params_.sourceContract != params_.destContract && relConfig_.onlySameIPAssetOrg) revert Errors.RelationshipModule_CannotRelateToOtherIPAssetOrg();
    }

    /// @dev Checks if the source or destination type of a relationship is allowed by the relationship config.
    /// @param collection_ The address of the collection of the relationship endpoint
    /// @param id_ The id of the relationship endpoint
    /// @param assetTypeMask_ The asset type mask of the relationship config, which contains the allowed asset types and the external asset flag
    /// @return result Whether the relationship endpoint is valid
    /// @return isAssetRegistry Whether the relationship endpoint is a Story Protocol IP Asset Registry
    function _checkRelationshipNode(address collection_, uint256 id_, uint256 assetTypeMask_) private view returns (bool result, bool isAssetRegistry) {
        if (IERC721(collection_).ownerOf(id_) == address(0)) return (false, false);
        isAssetRegistry = IP_ASSET_ORG_FACTORY.isIpAssetOrg(collection_);
        return (LibIPAssetMask._checkRelationshipNode(isAssetRegistry, id_, assetTypeMask_), isAssetRegistry);
    }

    /// @notice Converts the SetRelationshipConfigParams to a RelationshipConfig after validating them.
    /// @dev reverts if
    /// - the processor doesn't support IRelationshipProcessor interface
    /// - the TTL is not well configured.
    /// - the disputer is the zero address
    /// 
    /// @param params_ the SetRelationshipConfigParams
    /// @return the RelationshipConfig
    function _convertRelParams(Relationship.SetRelationshipConfigParams calldata params_) private view returns(Relationship.RelationshipConfig memory) {
        if (!params_.processor.supportsInterface(type(IRelationshipProcessor).interfaceId)) revert Errors.UnsupportedInterface("IRelationshipProcessor");
        if (params_.timeConfig.maxTtl < params_.timeConfig.minTtl) revert Errors.RelationshipModule_InvalidTTL();
        if (params_.disputer == address(0)) revert Errors.ZeroAddress();
        return Relationship.RelationshipConfig(
            LibIPAssetMask._convertToMask(params_.sourceIpAssets, params_.allowedExternalSource),
            LibIPAssetMask._convertToMask(params_.destIpAssets, params_.allowedExternalDest),
            params_.onlySameIPAssetOrg,
            IRelationshipProcessor(params_.processor),
            params_.disputer,
            params_.timeConfig
        );
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
}
