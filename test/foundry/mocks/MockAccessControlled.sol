// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { AccessControlled } from "contracts/access-control/AccessControlled.sol";

contract MockAccessControlled is AccessControlled {
    constructor(address accessControl) AccessControlled(accessControl) {}

    function exposeOnlyRole(bytes32 role) public onlyRole(role) {}    
}

