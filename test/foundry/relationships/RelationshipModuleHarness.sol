// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { RelationshipModuleBase } from "contracts/modules/relationships/RelationshipModuleBase.sol";

contract RelationshipModuleHarness is RelationshipModuleBase {

    constructor(address _franchiseRegistry) RelationshipModuleBase(_franchiseRegistry) {}

    function initialize(address accessControl) public initializer {
        __RelationshipModuleBase_init(accessControl);
    }

    function setRelationshipConfig(bytes32 relationshipId, SetRelationshipConfigParams calldata params) external {
        _setRelationshipConfig(relationshipId, params);
    }

    function unsetConfig(bytes32 relationshipId) external {
        _unsetConfig(relationshipId);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}

}