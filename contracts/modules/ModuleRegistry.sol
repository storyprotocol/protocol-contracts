// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { BaseModule } from "./base/BaseModule.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";

/// @title ModuleRegistry
/// @notice This contract is the source of truth for all modules that are registered in the protocol.
/// It's also the entrypoint for execution and configuration of modules, either directly by users
/// or by MODULE_EXECUTOR_ROLE holders.
contract ModuleRegistry is AccessControlled, Multicall {

    event ModuleAdded(address indexed ipOrg, string indexed moduleKey, BaseModule module);
    event ModuleRemoved(address indexed ipOrg, string indexed moduleKey, BaseModule module);
    event ModuleExecuted (
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

    address public constant PROTOCOL_LEVEL = address(0);

    constructor(address accessControl_) AccessControlled(accessControl_) { }

    /// Add a module to the protocol, that will be available for all IPOrgs.
    /// This is only callable by MODULE_REGISTRAR_ROLE holders.
    /// @param moduleKey short module descriptor
    /// @param moduleAddress address of the module
    function registerProtocolModule(
        string calldata moduleKey,
        BaseModule moduleAddress
    ) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        // TODO: inteface check in the module
        if (address(moduleAddress) == address(0)) {
            revert Errors.ZeroAddress();
        }
        _protocolModules[moduleKey] = moduleAddress;
        emit ModuleAdded(PROTOCOL_LEVEL, moduleKey, moduleAddress);
    }

    /// Remove a module from the protocol (all IPOrgs)
    /// This is only callable by MODULE_REGISTRAR_ROLE holders.
    /// @param moduleKey short module descriptor
    function removeProtocolModule(
        string calldata moduleKey
    ) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        if (address(_protocolModules[moduleKey]) == address(0)) {
            revert Errors.ModuleRegistry_ModuleNotRegistered(moduleKey);
        }
        BaseModule moduleAddress = _protocolModules[moduleKey];
        delete _protocolModules[moduleKey];
        emit ModuleRemoved(PROTOCOL_LEVEL, moduleKey, moduleAddress);
    }

    /// Get a module from the protocol, by its key.
    function moduleForKey(string calldata moduleKey) external view returns (BaseModule) {
        return _protocolModules[moduleKey];
    }

    /// Execution entrypoint, callable by any address on its own behalf.
    /// @param ipOrg_ address of the IPOrg, or address(0) for protocol-level stuff
    /// @param moduleKey_ short module descriptor
    /// @param moduleParams_ encoded params for module action
    /// @param preHookParams_ encoded params for pre action hooks
    /// @param postHookParams_ encoded params for post action hooks
    /// @return encoded result of the module execution
    function execute(
        IIPOrg ipOrg_,
        string calldata moduleKey_,
        bytes calldata moduleParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external returns (bytes memory) {
        return _execute(ipOrg_, msg.sender, moduleKey_, moduleParams_, preHookParams_, postHookParams_);
    }

    /// Execution entrypoint, callable by any MODULE_EXECUTOR_ROLE holder on behalf of any address.
    /// @param ipOrg_ address of the IPOrg, or address(0) for protocol-level stuff
    /// @param caller_ address requesting the execution
    /// @param moduleKey_ short module descriptor
    /// @param moduleParams_ encoded params for module action
    /// @param preHookParams_ encoded params for pre action hooks
    /// @param postHookParams_ encoded params for post action hooks
    /// @return encoded result of the module execution
    function execute(
        IIPOrg ipOrg_,
        address caller_,
        string calldata moduleKey_,
        bytes calldata moduleParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external onlyRole(AccessControl.MODULE_EXECUTOR_ROLE) returns (bytes memory) {
        return _execute(ipOrg_, caller_, moduleKey_, moduleParams_, preHookParams_, postHookParams_);
    }

    /// Configuration entrypoint, callable by any address on its own behalf.
    /// @param ipOrg_ address of the IPOrg, or address(0) for protocol-level stuff
    /// @param moduleKey_ short module descriptor
    /// @param params_ encoded params for module configuration
    function configure(
        IIPOrg ipOrg_,
        string calldata moduleKey_,
        bytes calldata params_
    ) external {
        _configure(ipOrg_, msg.sender, moduleKey_, params_);
    }

    /// Configuration entrypoint, callable by any MODULE_EXECUTOR_ROLE holder on behalf of any address.
    /// @param ipOrg_ address of the IPOrg, or address(0) for protocol-level stuff
    /// @param caller_ address requesting the execution
    /// @param moduleKey_ short module descriptor
    /// @param params_ encoded params for module configuration
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
        bytes calldata moduleParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) private returns (bytes memory result) {
        BaseModule module = _protocolModules[moduleKey_];
        if (address(module) == address(0)) {
            revert Errors.ModuleRegistry_ModuleNotRegistered(moduleKey_);
        }
        result = module.execute(ipOrg_, caller_, moduleParams_, preHookParams_, postHookParams_);
        emit ModuleExecuted(address(ipOrg_), moduleKey_, caller_, moduleParams_, preHookParams_, postHookParams_);
        return result;
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
