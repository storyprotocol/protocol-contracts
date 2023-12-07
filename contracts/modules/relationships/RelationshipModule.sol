// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { IRelationshipModule } from "contracts/interfaces/modules/relationships/IRelationshipModule.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { LibUintArrayMask } from "contracts/lib/LibUintArrayMask.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IRegistrationModule } from "contracts/interfaces/modules/registration/IRegistrationModule.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";

/// @title Relationship Module
/// @notice Contract that handles the creation and management of relationships between entities.
/// There are protocol level relationships, that are available for all IPOrgs, and IPOrg level relationships,
/// that are only available for a specific IPOrg.
/// Relationship types are configurable, allowing to link together different types of entities:
/// - IPA (Intellectual Property Asset)
/// - IPOrg Entry, including subcategories
/// - Licenses
/// - Addresses
/// - External NFTs
/// And combinations of them.
/// NOTE: This is an alpha version, a more efficient way of storing and verifying relationships will be implemented in the future.
contract RelationshipModule is BaseModule, IRelationshipModule, AccessControlled {

    using Address for address;

    mapping(string => LibRelationship.RelationshipType) private _protocolRelTypes;
    mapping(bytes32 => LibRelationship.RelationshipType) private _ipOrgRelTypes;

    uint256 private _relationshipIdCounter;
    mapping(uint256 => LibRelationship.Relationship) private _relationships;
    mapping(bytes32 => uint256) private _relHashes;

    constructor(
        BaseModule.ModuleConstruction memory params_,
        address accessControl_
    ) BaseModule(params_) AccessControlled(accessControl_) {}


    /// @notice Registers hooks for a specific hook type, based on IP Org and relationship type.
    /// @dev This function can only be called by the IP Org owner.
    /// @param hType_ The type of the hooks to register.
    /// @param ipOrg_ The IP Org for which the hooks are being registered.
    /// @param relType_ The relationship type for which the hooks are being registered.
    /// @param hooks_ The addresses of the hooks to register.
    /// @param hooksConfig_ The configurations for the hooks.
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

    /// Gets relationship type definition for a given relationship type name
    /// Will revert if no relationship type is found
    /// @param ipOrg_ IP Org address or zero address for protocol level relationships
    /// @param relType_ the name of the relationship type
    /// @return result the relationship type definition
    function getRelationshipType(address ipOrg_, string memory relType_) virtual override public view returns (LibRelationship.RelationshipType memory result) {
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

    /// Gets relationship definition for a given relationship id
    function getRelationship(uint256 relationshipId_) external view returns (LibRelationship.Relationship memory) {
        return _relationships[relationshipId_];
    }

    /// Gets relationship id for a given relationship
    function getRelationshipId(LibRelationship.Relationship calldata rel_) external virtual override view returns (uint256) {
        return _relHashes[keccak256(abi.encode(rel_))];
    }

    /// Checks if a relationship has been set
    function relationshipExists(LibRelationship.Relationship calldata rel_) external virtual override view returns (bool) {
        return _relHashes[keccak256(abi.encode(rel_))] != 0;
    }

    /// Relationship module supports configuration to add or remove relationship types
    function _configure(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) virtual override internal returns (bytes memory) {
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

    /// Auth check for caller, if wanting to configure a protocol level relationship type,
    /// caller must have RELATIONSHIP_MANAGER_ROLE, if it's an IPOrg level relationship type,
    /// caller must be the owner of the IPOrg
    /// @param ipOrg_ zero address for protocol level relationships, IPOrg address for IPOrg level relationships
    /// @param caller_ initiator of the configuration
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

    /// Gets the address and subtype mask to set a relationship type definition
    /// @param relatable_ which element category is being configured
    /// @param ipOrg_ IPOrg address
    /// @param allowedTypes_ ipOrg related types, if applicable
    /// @return a tuple with the accepted address and the subtype mask for this node of a
    /// relationship type definition
    function _addressConfigFor(
        LibRelationship.Relatables relatable_,
        address ipOrg_,
        uint8[] memory allowedTypes_
    ) private view returns (address, uint256) {
        if (relatable_ == LibRelationship.Relatables.IPA) {
            return (address(IPA_REGISTRY), 0);
        } else if (relatable_ == LibRelationship.Relatables.IPORG_ENTRY) {
            if (ipOrg_ == address(0)) {
                revert Errors.RelationshipModule_IpOrgRelatableCannotBeProtocolLevel();
            }
            _verifySupportedIpOrgIndexType(ipOrg_, allowedTypes_);
            return (ipOrg_, LibUintArrayMask._convertToMask(allowedTypes_));
        } else if (relatable_ == LibRelationship.Relatables.LICENSE) {
            return (address(LICENSE_REGISTRY), 0);
        } else if (relatable_ == LibRelationship.Relatables.ADDRESS) {
            return (LibRelationship.NO_ADDRESS_RESTRICTIONS, 0);
        } else if (relatable_ == LibRelationship.Relatables.EXTERNAL_NFT) {
            return (LibRelationship.NO_ADDRESS_RESTRICTIONS, 0);
        }
        revert Errors.RelationshipModule_InvalidRelatable();
    }

    function _verifySupportedIpOrgIndexType(
        address ipOrg_,
        uint8[] memory allowedTypes_
    ) private view {
        IRegistrationModule regModule = IRegistrationModule(
            MODULE_REGISTRY.protocolModule(ModuleRegistryKeys.REGISTRATION_MODULE)
        );
        uint256 length = allowedTypes_.length;
        for (uint256 i = 0; i < length; i++) {
            if (!regModule.isValidIpOrgAssetType(ipOrg_, allowedTypes_[i])) {
                revert Errors.RelationshipModule_UnsupportedIpOrgIndexType();
            }
        }
    }
    
    /// Configures a Relationship Type from the more user friendly AddRelationshipTypeParams struct,
    /// and adds it to the appropriate mapping (protocol or IPOrg)
    /// @param params_ AddRelationshipTypeParams
    function _addRelationshipType(LibRelationship.AddRelationshipTypeParams memory params_) private {
        (address src, uint256 srcSubtypesMask) = _addressConfigFor(params_.allowedElements.src, params_.ipOrg, params_.allowedSrcs);
        (address dst, uint256 dstSubtypesMask) = _addressConfigFor(params_.allowedElements.dst, params_.ipOrg, params_.allowedDsts);
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

    /// Removes a relationship type definition from the appropriate mapping (protocol or IPOrg)
    /// @param ipOrg_ zero address for protocol level relationships, IPOrg address for IPOrg level relationships
    /// @param relType_ name of the relationship type
    function _removeRelationshipType(address ipOrg_, string memory relType_) private {
        if (ipOrg_ == address(0)) {
            delete _protocolRelTypes[relType_];
        } else {
            delete _ipOrgRelTypes[keccak256(abi.encode(ipOrg_, relType_))];
        }
        emit RelationshipTypeUnset(relType_, ipOrg_);
    }

    /// Verifies that the relationship execute() wants to set is valid according to its type definition
    /// @param ipOrg_ IPOrg address or zero address for protocol level relationships
    /// @param params_ encoded params for module action
    function _verifyExecution(IIPOrg ipOrg_, address, bytes calldata params_) virtual override internal {
        LibRelationship.CreateRelationshipParams memory createParams = abi.decode(params_, (LibRelationship.CreateRelationshipParams));
        LibRelationship.RelationshipType memory relType = getRelationshipType(address(ipOrg_), createParams.relType);
        // Source checks
        if (createParams.srcAddress == address(0)) {
            revert Errors.RelationshipModule_InvalidSrcAddress();
        }
        if(relType.src != LibRelationship.NO_ADDRESS_RESTRICTIONS) {
            if (createParams.srcAddress != relType.src) {
                revert Errors.RelationshipModule_InvalidSrcAddress();
            }
        }
        if (relType.srcSubtypesMask != 0) {
            uint8 srcType = ipOrg_.ipOrgAssetType(createParams.srcId);
            if (!LibUintArrayMask._isAssetTypeOnMask(relType.srcSubtypesMask, srcType)) {
                revert Errors.RelationshipModule_InvalidSrcId();
            }
        }
        // Destination checks
        if (createParams.dstAddress == address(0)) {
            revert Errors.RelationshipModule_InvalidDstAddress();
        }
        if (relType.dst != LibRelationship.NO_ADDRESS_RESTRICTIONS) {
            if (createParams.dstAddress != relType.dst) {
                revert Errors.RelationshipModule_InvalidDstAddress();
            }
        }
        if (relType.dstSubtypesMask != 0) {
            uint8 dstType = ipOrg_.ipOrgAssetType(createParams.dstId);
            if (!LibUintArrayMask._isAssetTypeOnMask(relType.dstSubtypesMask, dstType)) {
                revert Errors.RelationshipModule_InvalidDstId();
            }
        }
    }

    /// Creates and stores a relationship and emits the RelationshipCreated event. Ignores first 2 parameters
    /// @param params_ encoded CreateRelationshipParams for module action
    /// @return encoded relationship id (uint256)
    function _performAction(IIPOrg, address, bytes calldata params_) virtual override internal returns (bytes memory) {
        LibRelationship.CreateRelationshipParams memory createParams = abi.decode(params_, (LibRelationship.CreateRelationshipParams));
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

    function _hookRegistryKey(
        IIPOrg ipOrg_,
        address,
        bytes calldata params_
    ) internal view virtual override returns(bytes32) {
        LibRelationship.CreateRelationshipParams memory createParams = abi.decode(params_, (LibRelationship.CreateRelationshipParams));
        return _generateRegistryKey(ipOrg_, createParams.relType);
    }

    function _generateRegistryKey(IIPOrg ipOrg_, string memory relType_) private pure returns(bytes32) {
        return keccak256(abi.encode(address(ipOrg_), relType_));
    }
}
