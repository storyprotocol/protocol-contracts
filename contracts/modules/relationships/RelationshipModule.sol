// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { LibUintArrayMask } from "./LibUintArrayMask.sol";
import { IRelationshipModule } from "contracts/interfaces/modules/relationships/IRelationshipModule.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";

contract RelationshipModule is BaseModule, IRelationshipModule {

    using Address for address;

    address public constant NO_ADDRESS_RESTRICTIONS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    mapping(string => LibRelationship.RelationshipType) private _protocolRelTypes;
    mapping(bytes32 => LibRelationship.RelationshipType) private _ipOrgRelTypes;

    uint256 private _relationshipIdCounter;
    mapping(uint256 => LibRelationship.Relationship) private _relationships;
    mapping(bytes32 => uint256) private _setRelationships;

    constructor(
        BaseModule.ModuleConstruction memory params_
    ) BaseModule(params_) {}

    function addressConfigFor(LibRelationship.Relatables relatables, address ipOrg, uint8[] calldata allowedTypes) public view returns (address, uint256) {
        if (relatables == LibRelationship.Relatables.IPA) {
            return (address(IPA_REGISTRY), LibUintArrayMask._convertToMask(allowedTypes));
        } else if (relatables == LibRelationship.Relatables.IPORG_ENTRY) {
            return (address(ipOrg), 0);
        } else if (relatables == LibRelationship.Relatables.LICENSE) {
            return (LICENSE_REGISTRY, 0);
        } else if (relatables == LibRelationship.Relatables.ADDRESS) {
            return (NO_ADDRESS_RESTRICTIONS, 0);
        } else if (relatables == LibRelationship.Relatables.EXTERNAL_NFT) {
            return (NO_ADDRESS_RESTRICTIONS, 0);
        }
        revert();
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

    function _configure(IIPOrg, address caller_, bytes calldata params_) virtual override internal {        
        Address.functionCall(address(this), params_, "");
    }
    
    // Internal method don't have selectors
    function _addRelationshipType(LibRelationship.AddRelationshipTypeParams calldata params_) public {
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

    function _removeRelationshipType(address ipOrg_, string calldata relType_) internal {
        if (ipOrg_ == address(0)) {
            delete _protocolRelTypes[relType_];
        } else {
            delete _ipOrgRelTypes[keccak256(abi.encode(ipOrg_, relType_))];
        }
        emit RelationshipTypeUnset(relType_, ipOrg_);
    }

    function _verifyExecution(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal {
        // 1. Check if relationship type exist for that org
        // 2. Check if source is allowed
        // 3. Check if destination is allowed

    }


    function _performAction(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal {
        // LibRelationship.Relationship memory rel = LibRelationship.Relationship(
        //     params_.relatedTypes,
        //     params_.srcAddress,
        //     params_.dstAddress,
        //     params_.srcId,
        //     params_.dstId
        // );
        // bytes32 relHash = getRelationshipHash(rel);
        // if (isRelationshipSet(relHash)) {
        //     revert Errors.RelationshipRegistry_RelationshipAlreadyExists();
        // }
        // unchecked {
        //     _relationshipIdCounter++;
        // }
        // _relationships[_relationshipIdCounter] = rel;
        // _setRelationships[relHash] = _relationshipIdCounter;
        // emit RelationshipSet(
        //     _relationshipIdCounter,
        //     params_.typeName,
        //     params_.RelatedTypes,
        //     params_.srcAddress,
        //     params_.dstAddress,
        //     params_.srcId,
        //     params_.dstId
        // );
    }
}