// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControlRoles } from "contracts/lib/AccessControlRoles.sol";

contract ModuleRegistry is AccessControlled {

    event ProtocolModuleAdded(bytes32 indexed moduleKey, string moduleKeyName, address moduleAddress);
    event ProtocolModuleRemoved(bytes32 indexed moduleKey, address moduleAddress);

    event IpOrgModuleAdded(bytes32 indexed moduleKey, string moduleName, address moduleAddress);


    mapping(bytes32 => address) private _protocolModules;

    constructor(address accessControl_) AccessControlled(accessControl_) { }

    function registerProtocolModule(
        string moduleKeyName,
        address moduleAddress
    ) external onlyRole(AccessControlRoles.MODULE_REGISTRAR_ROLE) {
        bytes32 moduleKey = moduleKeyFromKeyName(moduleKeyName);
        _protocolModules[moduleKey] = moduleAddress;
        emit ProtocolModuleAdded(moduleKey, moduleKeyName, moduleAddress);
    }

    function moduleKeyFromKeyName(string memory moduleKeyName) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(moduleKeyName));
    }
 


}