// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { RelationshipModuleBase } from "./RelationshipModuleBase.sol";
import { UPGRADER_ROLE, RELATIONSHIP_MANAGER_ROLE, RELATIONSHIP_DISPUTER_ROLE } from "contracts/access-control/ProtocolRoles.sol";

/**
 * @title ProtocolRelationshipModule
 * @dev Implementation of RelationshipModuleBase that allows relationship configs that will be used protocol wide.
 * The meaning and parameters of the relationships are to be defined in Story Protocol Improvement proposals.
 * Example: https://github.com/storyprotocol/protocol-contracts/issues/33
 * The relationship configs are set by the RELATIONSHIP_MANAGER_ROLE.
 * Upgrades are done by the UPGRADER_ROLE.
 */
contract ProtocolRelationshipModule is RelationshipModuleBase {

    constructor(address _franchiseRegistry) RelationshipModuleBase(_franchiseRegistry) {}

    function initialize(address accessControl) public initializer {
        __RelationshipModuleBase_init(accessControl);
    }

    /********* Setting Relationships *********/
    function setRelationshipConfig(bytes32 relationshipId, SetRelationshipConfigParams calldata params) external onlyRole(RELATIONSHIP_MANAGER_ROLE) {
        _setRelationshipConfig(relationshipId, params);
    }

    function unsetRelationshipConfig(bytes32 relationshipId) external onlyRole(RELATIONSHIP_MANAGER_ROLE) {
        _unsetRelationshipConfig(relationshipId);
    }


    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}