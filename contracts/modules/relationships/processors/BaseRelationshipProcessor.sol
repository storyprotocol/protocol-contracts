// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IRelationshipProcessor } from "contracts/interfaces/modules/relationships/processors/IRelationshipProcessor.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";


/// @title BaseRelationshipProcessor
/// @dev Base contract for relationship processors.
/// Relationship processors are used to process relationships between IP Assets before they are set.
/// They are set per relationship config in a IRelationshipModule
/// This base contracts implements ERC165 and checks if the caller is the relationship module.
/// All relationship processors must inherit from this contract.
abstract contract BaseRelationshipProcessor is IRelationshipProcessor, ERC165 {
    
    address internal immutable _RELATIONSHIP_MODULE;

    constructor(address relationshipModule_) {
        if(relationshipModule_ == address(0)) revert Errors.ZeroAddress();
        _RELATIONSHIP_MODULE = relationshipModule_;
    }

    
    /// @inheritdoc IRelationshipProcessor
    /// @dev Checks if the caller is the relationship module and calls implementation.
    function processRelationship(Relationship.RelationshipParams memory params_, bytes calldata data_, address caller_) external override returns(bool) {
        if(msg.sender != _RELATIONSHIP_MODULE) revert Errors.BaseRelationshipProcessor_OnlyRelationshipModule();
        return _processRelationship(params_, data_, caller_);
    }


    function _processRelationship(Relationship.RelationshipParams memory params_, bytes calldata data_, address caller_) internal virtual returns(bool);    

    function supportsInterface(
        bytes4 interfaceId_
    ) public view override(ERC165) returns (bool) {
        return super.supportsInterface(interfaceId_) || interfaceId_ == type(IRelationshipProcessor).interfaceId;
    }

}
