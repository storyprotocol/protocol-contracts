// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";


contract MockAccessControlledUpgradeable is AccessControlledUpgradeable {

    bool isInterfaceValid;

    function initialize(address accessControl) public initializer {
        __AccessControlledUpgradeable_init(accessControl);
    }

    function setIsInterfaceValid(bool isValid) public {
        isInterfaceValid = isValid;
    }

    function exposeOnlyRole(bytes32 role) public onlyRole(role) {}

    function _authorizeUpgrade(address newImplementation) internal virtual override {}

     function supportsInterface(bytes4 interfaceId) public view returns (bool) {
         if (isInterfaceValid) {
             return false;
         }
        return interfaceId == type(IAccessControl).interfaceId;
    }
}
