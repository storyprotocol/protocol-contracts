// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ModuleKey } from "contracts/lib/modules/Module.sol";
import { IGateway } from "contracts/interfaces/modules/IGateway.sol";
import { IModule } from "contracts/interfaces/modules/base/IModule.sol";

/// @title IModuleRegistry
/// @notice Module Registry Interface
interface IModuleRegistry {
    /// @notice Emits when a gateway was successfully registered by the protocol
    ///         for a specific dependency (module type + module function).
    /// @param key The identifier of the dependent module type.
    /// @param fn The function identifier of the dependent module type.
    /// @param gateway The gateway address granted permission to use the dependency.
    /// @param grant Whether the gateway was authorized to use the dependency.
    event ModuleAuthorizationGranted(ModuleKey indexed key, bytes4 fn, address indexed gateway, bool grant);

    /// @notice Emits when a brand new module is enrolled to the protocol.
    /// @param ipOrg The IP Org to which the module belongs.
    /// @param moduleKey The string identifier of the module type that was added.
    /// @param module The address of the module.
    event ModuleAdded(address indexed ipOrg, string moduleKey, address indexed module);

    /// @notice Emits when the protocol module for a module type is removed.
    /// @param key The identifier of the module type that was added.
    /// @param module The address of the removed module
    event ModuleRemoved(ModuleKey indexed key, address indexed module);

    /// @notice Emits when a module is executed for an IP Org.
    event ModuleExecuted(
        address indexed ipOrg,
        string moduleKey,
        address indexed caller,
        bytes selfParams,
        bytes[] preHookParams,
        bytes[] postHookParams
    );

    /// @notice Emits when a module is configured for an IP Org.
    event ModuleConfigured(address indexed ipOrg, string moduleKey, address indexed caller, bytes params);

    /// @notice Emits when a new hook is added for a specific IP Org.
    event HookAdded(address indexed ipOrg, string hookKey, address indexed hook);

    /// @notice Emits when a hook is removed for an IP Org.
    event HookRemoved(address indexed ipOrg, string hookKey, address indexed hook);

    /// @notice Registers a new module of a provided type to Story Protocol.
    /// @param key_ The bytes32 type of the module being registered.
    /// @param module_ The actual module being registered.
    function registerProtocolModule(ModuleKey key_, IModule module_) external;

    /// @notice Fetches the protocol module by its string identifier.
    /// @param key_ The string module type.
    /// @return The module associated with the module key.
    function protocolModule(string calldata key_) external view returns (address);

    /// @notice Fetches the protocol module bound to a module type.
    /// @param key_ The bytes32 module type.
    /// @return The module associated with the module key.
    function protocolModule(ModuleKey key_) external view returns (address);

    /// @notice Checks whether a gateway has permission to call a module function.
    /// @param key_ The module type.
    /// @param gateway_ The gateway which has the module as a dependency.
    /// @param fn_ The module function whose access is being checked for.
    function isAuthorized(ModuleKey key_, IGateway gateway_, bytes4 fn_) external view returns (bool);
}
