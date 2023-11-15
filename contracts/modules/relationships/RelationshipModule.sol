// SPDX-License-Identifier: BUSL-1.1
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
/// This allows Story Protocol to track attribution, IP remixes, sublicensing...
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

    function _hookRegistryAdmin()
        internal
        view
        virtual
        override
        returns (address)
    {
        return address(0); // TODO
    }

    /// Relationship module supports configuration to add or remove relationship types
    function _configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal {
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
    }

    /// Auth check for caller, if wanting to configure a protocol level relationship type,
    /// caller must have RELATIONSHIP_MANAGER_ROLE, if it's an IPOrg level relationship type,
    /// caller must be the owner of the IPOrg
    /// @param ipOrg_ zero address for protocol level relationships, IPOrg address for IPOrg level relationships
    /// @param caller_ initiator of the configuration
    function _verifyConfigCaller(IIPOrg ipOrg_, address caller_) private view {
        if (address(ipOrg_) == LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP) {
            if (!hasRole(AccessControl.RELATIONSHIP_MANAGER_ROLE, caller_)) {
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
    function addressConfigFor(
        LibRelationship.Relatables relatable_,
        address ipOrg_,
        uint8[] memory allowedTypes_
    ) private view returns (address, uint256) {
        if (relatable_ == LibRelationship.Relatables.IPA) {
            return (address(IPA_REGISTRY), 0);
        } else if (relatable_ == LibRelationship.Relatables.IPORG_ENTRY) {
            return (address(ipOrg_), LibUintArrayMask._convertToMask(allowedTypes_));
        } else if (relatable_ == LibRelationship.Relatables.LICENSE) {
            return (LICENSE_REGISTRY, 0);
        } else if (relatable_ == LibRelationship.Relatables.ADDRESS) {
            return (LibRelationship.NO_ADDRESS_RESTRICTIONS, 0);
        } else if (relatable_ == LibRelationship.Relatables.EXTERNAL_NFT) {
            return (LibRelationship.NO_ADDRESS_RESTRICTIONS, 0);
        }
        revert Errors.RelationshipModule_InvalidRelatable();
    }
    
    /// Configures a Relationship Type from the more user friendly AddRelationshipTypeParams struct,
    /// and adds it to the appropriate mapping (protocol or IPOrg)
    /// @param params_ AddRelationshipTypeParams
    function _addRelationshipType(LibRelationship.AddRelationshipTypeParams memory params_) private {
        (address src, uint256 srcSubtypesMask) = addressConfigFor(params_.allowedElements.src, params_.ipOrg, params_.allowedSrcs);
        (address dst, uint256 dstSubtypesMask) = addressConfigFor(params_.allowedElements.dst, params_.ipOrg, params_.allowedDsts);
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
        if (LibUintArrayMask._isAssetTypeOnMask(relType.srcSubtypesMask, createParams.srcType)) {
            revert Errors.RelationshipModule_InvalidSrcId();
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
        if (LibUintArrayMask._isAssetTypeOnMask(relType.srcSubtypesMask, createParams.dstType)) {
            revert Errors.RelationshipModule_InvalidDstId();
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
}
