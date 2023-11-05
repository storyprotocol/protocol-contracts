// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Errors } from "contracts/lib/Errors.sol";

/// @title Relatonship Registry
/// @notice This contract is used to register relationships in Story Protocol.
/// Relationships are directional, and they might be:
/// - Between (address, uint) and (address, uint)
/// - Between (address, uint) and (address)
/// - Between (address) and (address, uint)
/// Relationships have a type identifier, which a bytes32 value obtained from
/// keccak256(relationshipName).
/// Every relationship created will have a unique identifier, a sequential integer
/// starting from 1, that allows it to be referenced across the protocol.
/// TODO: This contract can only be written to by a relationship module registered in the
/// ModuleRegistry.
contract RelationshipRegistry {
    enum RelatedElements {
        UNDEFINED,
        ADDRESS_UINT_TO_ADDRESS_UINT,
        ADDRESS_UINT_TO_ADDRESS,
        ADDRESS_TO_ADDRESS_UINT
    }

    struct Relationship {
        bytes32 typeId;
        RelatedElements relatedElements;
        address srcAddress;
        address dstAddress;
        uint256 srcId;
        uint256 dstId;
    }

    struct SetRelationshipParams {
        string typeName;
        RelatedElements relatedElements;
        address srcAddress;
        address dstAddress;
        uint256 srcId;
        uint256 dstId;
    }

    event RelationshipSet(
        uint256 indexed relationshipId,
        string typeName,
        RelatedElements relatedElements,
        address srcAddress,
        address dstAddress,
        uint256 srcId,
        uint256 dstId
    );

    event RelationshipUnset(uint256 indexed relationshipId);

    uint256 private _relationshipIdCounter;
    mapping(uint256 => Relationship) private _relationships;
    mapping(bytes32 => uint256) private _setRelationships;

    address public immutable MODULE_REGISTRY;

    constructor(address moduleRegistry_) {
        if (moduleRegistry_ == address(0)) {
            revert Errors.RelationshipRegistry_ModuleRegistryZeroAddress();
        }
        MODULE_REGISTRY = moduleRegistry_;
    }

    function setRelationship(SetRelationshipParams calldata params_) external {
        _validateParams(params_);
        // TODO: Validate that typeName can be set by the caller
        Relationship memory rel = Relationship(
            getRelationsipTypeId(params_.typeName),
            params_.relatedElements,
            params_.srcAddress,
            params_.dstAddress,
            params_.srcId,
            params_.dstId
        );
        bytes32 relHash = getRelationshipHash(rel);
        if (isRelationshipSet(relHash)) {
            revert Errors.RelationshipRegistry_RelationshipAlreadyExists();
        }
        unchecked {
            _relationshipIdCounter++;
        }
        _relationships[_relationshipIdCounter] = rel;
        _setRelationships[relHash] = _relationshipIdCounter;
        emit RelationshipSet(
            _relationshipIdCounter,
            params_.typeName,
            params_.relatedElements,
            params_.srcAddress,
            params_.dstAddress,
            params_.srcId,
            params_.dstId
        );
    }

    function unsetRelationship(bytes32 relationshipHash_) external {
        if (!isRelationshipSet(relationshipHash_)) {
            revert Errors.RelationshipRegistry_RelationshipDoesNotExist();
        }
        uint256 relationshipId = _setRelationships[relationshipHash_];
        delete _setRelationships[relationshipHash_];
        delete _relationships[relationshipId];
        emit RelationshipUnset(relationshipId);
    }

    function getRelationshipId(
        Relationship calldata rel_
    ) external view returns (uint256) {
        return _setRelationships[getRelationshipHash(rel_)];
    }

    function getRelationshipIdFromRelHash(
        bytes32 relationshipHash_
    ) external view returns (uint256) {
        return _setRelationships[relationshipHash_];
    }

    function isRelationshipSet(
        Relationship calldata rel_
    ) external view returns (bool) {
        return _setRelationships[getRelationshipHash(rel_)] != 0;
    }

    function getRelationship(
        uint256 relationshipId_
    ) external view returns (Relationship memory) {
        return _relationships[relationshipId_];
    }

    function isRelationshipSet(
        bytes32 relationshipHash_
    ) public view returns (bool) {
        return _setRelationships[relationshipHash_] != 0;
    }

    function getRelationsipTypeId(
        string calldata typeName_
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(typeName_));
    }

    function getRelationshipHash(
        Relationship memory rel_
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    rel_.typeId,
                    rel_.relatedElements,
                    rel_.srcAddress,
                    rel_.dstAddress,
                    rel_.srcId,
                    rel_.dstId
                )
            );
    }

    function _validateParams(
        SetRelationshipParams calldata params_
    ) private pure {
        if (params_.relatedElements == RelatedElements.UNDEFINED) {
            revert Errors.RelationshipRegistry_UndefinedElements();
        }
        if (
            params_.srcAddress == address(0) || params_.dstAddress == address(0)
        ) {
            revert Errors.RelationshipRegistry_RelationshipHaveZeroAddress();
        }
        if (
            params_.relatedElements == RelatedElements.ADDRESS_UINT_TO_ADDRESS ||
            params_.relatedElements == RelatedElements.ADDRESS_TO_ADDRESS_UINT
        ) {
            if (params_.srcAddress == params_.dstAddress) {
                revert Errors.RelationshipRegistry_RelatingSameAsset();
            }
        }
        if (
            params_.relatedElements ==
            RelatedElements.ADDRESS_UINT_TO_ADDRESS_UINT
        ) {
            if (
                params_.srcAddress == params_.dstAddress &&
                params_.srcId == params_.dstId
            ) {
                revert Errors.RelationshipRegistry_RelatingSameAsset();
            }
        } else {
            revert Errors.RelationshipRegistry_UnsupportedRelatedElements();
        }
    }
}
