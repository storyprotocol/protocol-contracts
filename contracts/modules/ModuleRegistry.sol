// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { BaseModule } from "./base/BaseModule.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";

contract ModuleRegistry is AccessControlled, Multicall {

    event ProtocolModuleAdded(string indexed moduleKey, BaseModule module);
    event ProtocolModuleRemoved(string indexed moduleKey, BaseModule module);
    event ExecutedModule(
        address indexed ipOrg,
        string indexed moduleKey,
        address indexed caller,
        bytes selfParams,
        bytes[] preHookParams,
        bytes[] postHookParams
    );
    event ModuleConfigured(
        address indexed ipOrg,
        string indexed moduleKey,
        address indexed caller,
        bytes params
    );

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

    function execute(
        IIPOrg ipOrg_,
        string calldata moduleKey_,
        bytes calldata selfParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external {
        _execute(ipOrg_, msg.sender, moduleKey_, selfParams_, preHookParams_, postHookParams_);
    }

    function execute(
        IIPOrg ipOrg_,
        address caller_,
        string calldata moduleKey_,
        bytes calldata selfParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external onlyRole(AccessControl.MODULE_EXECUTOR_ROLE) {
        _execute(ipOrg_, caller_, moduleKey_, selfParams_, preHookParams_, postHookParams_);
    }

    function configure(
        IIPOrg ipOrg_,
        string calldata moduleKey_,
        bytes calldata params_
    ) external {
        _configure(ipOrg_, msg.sender, moduleKey_, params_);
    }

    function configure(
        IIPOrg ipOrg_,
        address caller_,
        string calldata moduleKey_,
        bytes calldata params_
    ) external onlyRole(AccessControl.MODULE_EXECUTOR_ROLE) {
        _configure(ipOrg_, caller_, moduleKey_, params_);
    }

    function _execute(
        IIPOrg ipOrg_,
        address caller_,
        string calldata moduleKey_,
        bytes calldata selfParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) private {
        BaseModule module = _protocolModules[moduleKey_];
        if (address(module) == address(0)) {
            revert Errors.ModuleRegistry_ModuleNotRegistered(moduleKey_);
        }
        module.execute(ipOrg_, caller_, selfParams_, preHookParams_, postHookParams_);
        emit ExecutedModule(address(ipOrg_), moduleKey_, caller_, selfParams_, preHookParams_, postHookParams_);
    }

    function _configure(
        IIPOrg ipOrg_,
        address caller_,
        string calldata moduleKey_,
        bytes calldata params_
    ) private {
        // if (IIPOrg(ipOrg_).owner() != msg.sender) {
        //     revert Errors.ModuleRegistry_CallerNotOrgOwner();
        //}
        BaseModule module = _protocolModules[moduleKey_];
        if (address(module) == address(0)) {
            revert Errors.ModuleRegistry_ModuleNotRegistered(moduleKey_);
        }
        module.configure(ipOrg_, caller_, params_);
        emit ModuleConfigured(address(ipOrg_), moduleKey_, caller_, params_);
    }
}