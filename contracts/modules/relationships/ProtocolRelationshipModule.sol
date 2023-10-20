// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { RelationshipModuleBase } from "./RelationshipModuleBase.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";

/// @title ProtocolRelationshipModule
/// @dev Implementation of RelationshipModuleBase that allows relationship configs that will be used protocol wide.
/// The meaning and parameters of the relationships are to be defined in Story Protocol Improvement Proposals.
/// Example: https://github.com/storyprotocol/protocol-contracts/issues/33
/// The relationship configs are set by the RELATIONSHIP_MANAGER_ROLE.
/// Upgrades are done by the UPGRADER_ROLE.
contract ProtocolRelationshipModule is RelationshipModuleBase {

    constructor(address ipAssetOrgFactory_) RelationshipModuleBase(ipAssetOrgFactory_) {}

    function initialize(address accessControl_) public initializer {
        __RelationshipModuleBase_init(accessControl_);
    }

    /********* Setting Relationships *********/
    function setRelationshipConfig(string calldata name_, Relationship.SetRelationshipConfigParams calldata params_) external onlyRole(AccessControl.RELATIONSHIP_MANAGER_ROLE) returns (bytes32 relationshipId) {
        return _setRelationshipConfig(name_, params_);
    }

    function unsetRelationshipConfig(bytes32 relationshipId_) external onlyRole(AccessControl.RELATIONSHIP_MANAGER_ROLE) {
        _unsetRelationshipConfig(relationshipId_);
    }


    function _authorizeUpgrade(
        address newImplementation_
    ) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}

}
