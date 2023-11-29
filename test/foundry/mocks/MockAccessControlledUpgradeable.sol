// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";

contract MockAccessControlledUpgradeable is AccessControlledUpgradeable {

    function initialize(address accessControl) public initializer {
        __AccessControlledUpgradeable_init(accessControl);
    }

    function exposeOnlyRole(bytes32 role) public onlyRole(role) {}

    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}
