// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { RelationshipModuleBase } from "./RelationshipModuleBase.sol";
import { UPGRADER_ROLE, RELATIONSHIP_MANAGER_ROLE, RELATIONSHIP_DISPUTER_ROLE } from "contracts/access-control/ProtocolRoles.sol";

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