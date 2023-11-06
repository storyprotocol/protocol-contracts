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

    function addressConfigFor(LibRelationship.Relatables relatables, address ipOrg, uint8[] memory allowedTypes) public view returns (address, uint256) {
        if (relatables == LibRelationship.Relatables.IPA) {
            return (address(IPA_REGISTRY), LibUintArrayMask._convertToMask(allowedTypes));
        } else if (relatables == LibRelationship.Relatables.IPORG_ENTRY) {
            return (address(ipOrg), 0);
        } else if (relatables == LibRelationship.Relatables.LICENSE) {
            return (LICENSE_REGISTRY, 0);
        } else if (relatables == LibRelationship.Relatables.ADDRESS) {
            return (LibRelationship.NO_ADDRESS_RESTRICTIONS, 0);
        } else if (relatables == LibRelationship.Relatables.EXTERNAL_NFT) {
            return (LibRelationship.NO_ADDRESS_RESTRICTIONS, 0);
        }
        revert Errors.RelationshipModule_InvalidRelatable();
    }

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

    function getRelationship(uint256 relationshipId_) external view returns (LibRelationship.Relationship memory) {
        return _relationships[relationshipId_];
    }

    function getRelationshipId(LibRelationship.Relationship calldata rel_) external virtual override view returns (uint256) {
        return _relHashes[keccak256(abi.encode(rel_))];
    }

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

    function _removeRelationshipType(address ipOrg_, string memory relType_) private {
        if (ipOrg_ == address(0)) {
            delete _protocolRelTypes[relType_];
        } else {
            delete _ipOrgRelTypes[keccak256(abi.encode(ipOrg_, relType_))];
        }
        emit RelationshipTypeUnset(relType_, ipOrg_);
    }

    function _verifyExecution(IIPOrg ipOrg_, address, bytes calldata params_) virtual override internal {
        LibRelationship.CreateRelationshipParams memory createParams = abi.decode(params_, (LibRelationship.CreateRelationshipParams));
        LibRelationship.RelationshipType memory relType = getRelationshipType(address(ipOrg_), createParams.relType);
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