// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { BaseModule } from "./base/BaseModule.sol";

contract ModuleRegistry is AccessControlled {

    event ProtocolModuleAdded(string indexed moduleKey, BaseModule module);
    event ProtocolModuleRemoved(string indexed moduleKey, BaseModule module);

    mapping(string => BaseModule) private _protocolModules;

    constructor(address accessControl_) AccessControlled(accessControl_) { }

    function registerProtocolModule(
        string calldata moduleKey,
        BaseModule moduleAddress
    ) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        // TODO: inteface check in the module
        if (address(moduleAddress) == address(0)) {
            revert Errors.ZeroAddress();
        }
        _protocolModules[moduleKey] = moduleAddress;
        emit ProtocolModuleAdded(moduleKey, moduleAddress);
    }

    function removeProtocolModule(
        string calldata moduleKey
    ) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        if (address(_protocolModules[moduleKey]) == address(0)) {
            revert Errors.ModuleRegistry_ModuleNotRegistered(moduleKey);
        }
        BaseModule moduleAddress = _protocolModules[moduleKey];
        delete _protocolModules[moduleKey];
        emit ProtocolModuleRemoved(moduleKey, moduleAddress);
    }

    function moduleForKey(string calldata moduleKey) external view returns (BaseModule) {
        return _protocolModules[moduleKey];
    }
 
}