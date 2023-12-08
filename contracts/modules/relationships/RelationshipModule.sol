// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { IRelationshipModule } from "contracts/interfaces/modules/relationships/IRelationshipModule.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { BitMask } from "contracts/lib/BitMask.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IRegistrationModule } from "contracts/interfaces/modules/registration/IRegistrationModule.sol";
import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { ModuleKey, REGISTRATION_MODULE_KEY, RELATIONSHIP_MODULE_KEY } from "contracts/lib/modules/Module.sol";

/// @title Relationship Module
/// @notice Handles creation and management of relationships between IP entities.
///         Note that two types of relationships exist, those that are available across
///         all IP Orgs (protocol-wide), and those that are exclusive to IP Orgs.
///         Relationship types link different IP entities together, including:
///         - IPAs (Intellectual Property Assets)
///         - IPOrg Assets
///         - Licenses
///         - Addresses
///         - External NFTs
contract RelationshipModule is BaseModule, IRelationshipModule, AccessControlled {
    using Address for address;

    /// @notice Maps protocol-wide relationship types to their definitions.
    mapping(string => LibRelationship.RelationshipType) private _protocolRelTypes;

    /// @notice Maps IP Org relationship types to their definitions.
    /// @dev The key is given by the keccak-256 hash of (string relName, address ipOrg).
    mapping(bytes32 => LibRelationship.RelationshipType) private _ipOrgRelTypes;

    /// @dev Internal counter for tracking the current relationship id.
    uint256 private _relationshipIdCounter;

    /// @dev Tracks relationship ids to their relationships.
    mapping(uint256 => LibRelationship.Relationship) private _relationships;

    /// @dev Maps relationship hashes to their underlying ids.
    mapping(bytes32 => uint256) private _relHashes;

    /// @notice Creates a new relationship module.
    /// @param params_ Core attributes required by all protocol modules.
    /// @param accessControl_ Global access singleton contract used for protocol authorization.
    constructor(
        BaseModule.ModuleConstruction memory params_,
        address accessControl_
    ) BaseModule(params_) AccessControlled(accessControl_) {}

    /// @notice Gets the protocol-wide module key for the relationship module.
    /// @return The protocol-wide key configured for the relationship module.
    function moduleKey() public pure override(BaseModule, IModule) returns (ModuleKey) {
        return RELATIONSHIP_MODULE_KEY;
    }

    /// @notice Registers hooks on behalf of an IP Org for a specific hook and relationship type.
    /// @dev This function can only be called by the IP Org owner.
    /// @param hType_ The type of hooks to register.
    /// @param ipOrg_ The IP Org for which the hooks are being registered for.
    /// @param relType_ The relationship type he hooks are being registered under.
    /// @param hooks_ The addresses of the hooks to register.
    /// @param hooksConfig_ The associated configurations for the hooks.
    function registerHooks(
        HookType hType_,
        IIPOrg ipOrg_,
        string calldata relType_,
        address[] calldata hooks_,
        bytes[] calldata hooksConfig_
    ) external onlyIpOrgOwner(ipOrg_) {
        bytes32 registryKey = _generateRegistryKey(ipOrg_, relType_);
        registerHooks(hType_, ipOrg_, registryKey, hooks_, hooksConfig_);
    }

    /// @notice Gets the type definition for a given relationship type name.
    /// @dev This function Will revert if no relationship type is found.
    /// @param ipOrg_ Address of the IP Org or zero address if it is a protocol-wide relationship.
    /// @param relType_ the name of the relationship type.
    /// @return result The relationship type definition.
    function getRelationshipType(
        address ipOrg_,
        string memory relType_
    ) public view virtual override returns (LibRelationship.RelationshipType memory result) {
        if (ipOrg_ == LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP) {
            result = _protocolRelTypes[relType_];
        } else {
            result = _ipOrgRelTypes[keccak256(abi.encode(ipOrg_, relType_))];
        }
        if (result.src == address(0) || result.dst == address(0)) {
            revert Errors.RelationshipModule_RelTypeNotSet(relType_);
        }
        return result;
    }

    /// @notice Gets the relationship definition for a given relationship id.
    /// @param relationshipId_ The identifier for the relationship.
    /// @return The underlying relationship.
    function getRelationship(uint256 relationshipId_) external view returns (LibRelationship.Relationship memory) {
        return _relationships[relationshipId_];
    }

    /// @notice Gets the relationship id for a given relationship.
    /// @param rel_ The data structure of the relationship.
    /// @return The id of the relationship.
    function getRelationshipId(
        LibRelationship.Relationship calldata rel_
    ) external view virtual override returns (uint256) {
        return _relHashes[keccak256(abi.encode(rel_))];
    }

    /// @notice Checks whether a given relationship exists or not.
    /// @param rel_ The relationship entity being checked for.
    /// @return True if the relationship exists, False otherwise.
    function relationshipExists(
        LibRelationship.Relationship calldata rel_
    ) external view virtual override returns (bool) {
        return _relHashes[keccak256(abi.encode(rel_))] != 0;
    }

    /// @dev Configures a relationship, adding or removing new relationship types.
    // @param ipOrg_ IP Org address or zero address if configuring across the protocol.
    // @param params_ Encoded relationship data (see LibRelationship for details).
    function _configure(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) internal virtual override returns (bytes memory) {
        _verifyConfigCaller(ipOrg_, caller_);
        (bytes32 configType, bytes memory configData) = abi.decode(params_, (bytes32, bytes));
        if (configType == LibRelationship.ADD_REL_TYPE_CONFIG) {
            _addRelationshipType(abi.decode(configData, (LibRelationship.AddRelationshipTypeParams)));
        } else if (configType == LibRelationship.REMOVE_REL_TYPE_CONFIG) {
            string memory relType = abi.decode(configData, (string));
            _removeRelationshipType(address(ipOrg_), relType);
        } else {
            revert Errors.RelationshipModule_InvalidConfigOperation();
        }
        return "";
    }

    /// @dev Verifies whether configuration for a relationship is authorized. For
    ///      protocol-wide relationships, the caller must have the RELATIONSHIP_MANAGER_ROLE.
    ///      For IP Org relationships, the caller must be the owner of the IP Org.
    /// @param ipOrg_ Addrss of the IP Org, or the zero address for protocol-wide relationships.
    /// @param caller_ Address of the caller of the configuration setting.
    function _verifyConfigCaller(IIPOrg ipOrg_, address caller_) private view {
        if (address(ipOrg_) == LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP) {
            if (!_hasRole(AccessControl.RELATIONSHIP_MANAGER_ROLE, caller_)) {
                revert Errors.MissingRole(AccessControl.RELATIONSHIP_MANAGER_ROLE, caller_);
            }
        } else {
            if (ipOrg_.owner() != caller_) {
                revert Errors.RelationshipModule_CallerNotIpOrgOwner();
            }
        }
    }

    /// @notice Gets the controlling address and subtype mask for setting relationship type definitions.
    /// @param relatable_ The type of entity being set as part of a relationship.
    /// @param ipOrg_ Address of the IP Org or the zero address (if protocol-wide).
    /// @param allowedTypes_ The allowable set of IP Org relationship types.
    /// @return The controlling address and subtype mask for applying the relationship typedefs.
    function _addressConfigFor(
        LibRelationship.Relatables relatable_,
        address ipOrg_,
        uint8[] memory allowedTypes_
    ) private view returns (address, uint256) {
        if (relatable_ == LibRelationship.Relatables.Ipa) {
            return (address(IPA_REGISTRY), 0);
        } else if (relatable_ == LibRelationship.Relatables.IpOrgEntry) {
            if (ipOrg_ == address(0)) {
                revert Errors.RelationshipModule_IpOrgRelatableCannotBeProtocolLevel();
            }
            _verifySupportedIpOrgIndexType(ipOrg_, allowedTypes_);
            if (allowedTypes_.length == 0) {
                revert Errors.EmptyArray();
            }
            return (ipOrg_, BitMask.convertToMask(allowedTypes_));
        } else if (relatable_ == LibRelationship.Relatables.License) {
            return (address(LICENSE_REGISTRY), 0);
        } else if (relatable_ == LibRelationship.Relatables.Address) {
            return (LibRelationship.NO_ADDRESS_RESTRICTIONS, 0);
        } else if (relatable_ == LibRelationship.Relatables.ExternalNft) {
            return (LibRelationship.NO_ADDRESS_RESTRICTIONS, 0);
        }
        revert Errors.RelationshipModule_InvalidRelatable();
    }

    /// @dev Checks whether provided relationship types are valid.
    /// @param ipOrg_ Address of the IP Org or zero address (if protocol-wide).
    /// @param allowedTypes_ The provided set of relationship types being checked for.
    function _verifySupportedIpOrgIndexType(address ipOrg_, uint8[] memory allowedTypes_) private view {
        IRegistrationModule regModule = IRegistrationModule(
            address(MODULE_REGISTRY.protocolModule(REGISTRATION_MODULE_KEY))
        );
        uint256 length = allowedTypes_.length;
        for (uint256 i = 0; i < length; i++) {
            if (!regModule.isValidIpOrgAssetType(ipOrg_, allowedTypes_[i])) {
                revert Errors.RelationshipModule_UnsupportedIpOrgIndexType();
            }
        }
    }

    /// @dev Configures a new protocol-wide or IP Org relationship type.
    /// @param params_ Parameters associated with the relationship type creation.
    function _addRelationshipType(LibRelationship.AddRelationshipTypeParams memory params_) private {
        (address src, uint256 srcSubtypesMask) = _addressConfigFor(
            params_.allowedElements.src,
            params_.ipOrg,
            params_.allowedSrcs
        );
        (address dst, uint256 dstSubtypesMask) = _addressConfigFor(
            params_.allowedElements.dst,
            params_.ipOrg,
            params_.allowedDsts
        );
        LibRelationship.RelationshipType memory relDef = LibRelationship.RelationshipType({
            src: src,
            srcSubtypesMask: srcSubtypesMask,
            dst: dst,
            dstSubtypesMask: dstSubtypesMask
        });
        if (params_.ipOrg == LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP) {
            _protocolRelTypes[params_.relType] = relDef;
        } else {
            _ipOrgRelTypes[keccak256(abi.encode(params_.ipOrg, params_.relType))] = relDef;
        }
        emit RelationshipTypeSet(
            params_.relType,
            params_.ipOrg,
            relDef.src,
            params_.allowedElements.src,
            relDef.srcSubtypesMask,
            relDef.dst,
            params_.allowedElements.dst,
            relDef.dstSubtypesMask
        );
    }

    /// @dev Removes a relationship type from an IP Org or across thep rotocol.
    /// @param ipOrg_ Address of the IP Org or the zero address (if protocol-wide).
    /// @param relType_ Name of the relationship type.
    function _removeRelationshipType(address ipOrg_, string memory relType_) private {
        if (ipOrg_ == address(0)) {
            delete _protocolRelTypes[relType_];
        } else {
            delete _ipOrgRelTypes[keccak256(abi.encode(ipOrg_, relType_))];
        }
        emit RelationshipTypeUnset(relType_, ipOrg_);
    }

    /// @dev Verifies that a relationship config is valid according to its typedef.
    /// @param ipOrg_ Address of the IP Org or the zero address (if protocol-wide).
    /// @param params_ Encoded parameters used for relationship processing (see LibRelationship).
    function _verifyExecution(IIPOrg ipOrg_, address, bytes calldata params_) internal virtual override {
        LibRelationship.CreateRelationshipParams memory createParams = abi.decode(
            params_,
            (LibRelationship.CreateRelationshipParams)
        );
        LibRelationship.RelationshipType memory relType = getRelationshipType(address(ipOrg_), createParams.relType);
        // Source checks
        if (createParams.srcAddress == address(0)) {
            revert Errors.RelationshipModule_InvalidSrcAddress();
        }
        if (relType.src != LibRelationship.NO_ADDRESS_RESTRICTIONS && createParams.srcAddress != relType.src) {
            revert Errors.RelationshipModule_InvalidSrcAddress();
        }
        if (
            relType.srcSubtypesMask != 0 &&
            !BitMask.isSet(relType.srcSubtypesMask, ipOrg_.ipOrgAssetType(createParams.srcId))
        ) {
            revert Errors.RelationshipModule_InvalidSrcId();
        }
        // Destination checks
        if (createParams.dstAddress == address(0)) {
            revert Errors.RelationshipModule_InvalidDstAddress();
        }
        if (relType.dst != LibRelationship.NO_ADDRESS_RESTRICTIONS && createParams.dstAddress != relType.dst) {
            revert Errors.RelationshipModule_InvalidDstAddress();
        }
        if (
            relType.dstSubtypesMask != 0 &&
            !BitMask.isSet(relType.dstSubtypesMask, ipOrg_.ipOrgAssetType(createParams.dstId))
        ) {
            revert Errors.RelationshipModule_InvalidDstId();
        }
    }

    /// @dev Processes the configuration of a new relationship.
    /// @param params_ Encoded parameters used for relationship processing (see LibRelationship).
    /// @return The encoded uint256 relationship identifier.
    function _performAction(IIPOrg, address, bytes memory params_) internal virtual override returns (bytes memory) {
        LibRelationship.CreateRelationshipParams memory createParams = abi.decode(
            params_,
            (LibRelationship.CreateRelationshipParams)
        );
        uint256 relationshipId = ++_relationshipIdCounter;
        LibRelationship.Relationship memory rel = LibRelationship.Relationship({
            relType: createParams.relType,
            srcAddress: createParams.srcAddress,
            dstAddress: createParams.dstAddress,
            srcId: createParams.srcId,
            dstId: createParams.dstId
        });
        _relationships[relationshipId] = rel;
        _relHashes[keccak256(abi.encode(rel))] = relationshipId;
        emit RelationshipCreated(
            relationshipId,
            createParams.relType,
            createParams.srcAddress,
            createParams.srcId,
            createParams.dstAddress,
            createParams.dstId
        );
        return abi.encode(relationshipId);
    }

    /// @dev Gets the hook registry key associated with an IP Org and relationship type.
    /// @param ipOrg_ Address of the IP Org under which the hook is registered.
    /// @param params_ Relationship config params from which the type is sourced.
    function _hookRegistryKey(
        IIPOrg ipOrg_,
        address,
        bytes calldata params_
    ) internal view virtual override returns (bytes32) {
        LibRelationship.CreateRelationshipParams memory createParams = abi.decode(
            params_,
            (LibRelationship.CreateRelationshipParams)
        );
        return _generateRegistryKey(ipOrg_, createParams.relType);
    }

    /// @dev Creates a new hooks registration key for the relationship module.
    /// @param ipOrg_ The IP Org under which the key is associated.
    function _generateRegistryKey(IIPOrg ipOrg_, string memory relType_) private pure returns (bytes32) {
        return keccak256(abi.encode(address(ipOrg_), relType_));
    }
}
