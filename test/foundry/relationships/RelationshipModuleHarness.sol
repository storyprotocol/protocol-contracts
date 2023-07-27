// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { RelationshipModuleBase } from "contracts/modules/relationships/RelationshipModuleBase.sol";

contract RelationshipModuleHarness is RelationshipModuleBase {

    constructor(address _franchiseRegistry) RelationshipModuleBase(_franchiseRegistry) {}

    function initialize(address accessControl) public initializer {
        __RelationshipModuleBase_init(accessControl);
    }

    function setRelationshipConfig(string calldata name, SetRelationshipConfigParams calldata params) external returns(bytes32 relationshipId) {
        return _setRelationshipConfig(name, params);
    }

    function unsetRelationshipConfig(bytes32 relationshipId) external {
        _unsetRelationshipConfig(relationshipId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}

}