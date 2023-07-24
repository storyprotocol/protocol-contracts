// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IRelationshipProcessor } from "./IRelationshipProcessor.sol";
import { ZeroAddress } from "contracts/errors/General.sol";
import { IRelationshipModule } from "../IRelationshipModule.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract BaseRelationshipProcessor is IRelationshipProcessor, ERC165 {
    
    address internal immutable _RELATIONSHIP_MODULE;
    error OnlyRelationshipModule();

    constructor(address _relationshipModule) {
        if(_relationshipModule == address(0)) revert ZeroAddress();
        _RELATIONSHIP_MODULE = _relationshipModule;
    }

    function processRelationship(IRelationshipModule.RelationshipParams memory params, bytes calldata data, address caller) external override returns(bool) {
        if(msg.sender != _RELATIONSHIP_MODULE) revert OnlyRelationshipModule();
        return _processRelationship(params, data, caller);
    }

    function _processRelationship(IRelationshipModule.RelationshipParams memory params, bytes calldata data, address caller) internal virtual returns(bool);    

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IRelationshipProcessor).interfaceId;
    }

}