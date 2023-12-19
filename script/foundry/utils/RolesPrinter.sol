// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { ModuleKey, RELATIONSHIP_MODULE_KEY, LICENSING_MODULE_KEY, REGISTRATION_MODULE_KEY } from "contracts/lib/modules/Module.sol";

contract RolesPrinter is Script {
    function run() view public {
        console.log("PROTOCOL_ADMIN_ROLE");
        console.logBytes32(bytes32(0));
        console.log("UPGRADER_ROLE");
        console.logBytes32(keccak256("UPGRADER_ROLE"));

        console.log("RELATIONSHIP_MANAGER_ROLE");
        console.logBytes32(keccak256("RELATIONSHIP_MANAGER_ROLE"));

        console.log("LICENSING_MANAGER_ROLE");
        console.logBytes32(keccak256("LICENSING_MANAGER_ROLE"));

        console.log("MODULE_REGISTRAR_ROLE");
        console.logBytes32(keccak256("MODULE_REGISTRAR_ROLE"));

        console.log("MODULE_EXECUTOR_ROLE");
        console.logBytes32(keccak256("MODULE_EXECUTOR_ROLE"));

        console.log("HOOK_CALLER_ROLE");
        console.logBytes32(keccak256("HOOK_CALLER_ROLE"));

        console.log("RELATIONSHIP_MODULE_KEY");
        console.logBytes32(ModuleKey.unwrap(RELATIONSHIP_MODULE_KEY));

        console.log("LICENSING_MODULE_KEY");
        console.logBytes32(ModuleKey.unwrap(LICENSING_MODULE_KEY));

        console.log("REGISTRATION_MODULE_KEY");
        console.logBytes32(ModuleKey.unwrap(REGISTRATION_MODULE_KEY));

    }
}
