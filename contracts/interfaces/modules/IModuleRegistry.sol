// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title IModuleRegistry
/// @notice Module Registry Interface
interface IModuleRegistry {

    /// @notice Emits when a new module is added for a specific IP Org.
    event ModuleAdded(
        address indexed ipOrg,
        string indexed moduleKey,
        address indexed module
    );

    /// @notice Emits when a module is removed for an IP Org.
    event ModuleRemoved(
        address indexed ipOrg,
        string indexed moduleKey,
        address indexed module
    );

    /// @notice Emits when a module is executed for an IP Org.
    event ModuleExecuted (
        address indexed ipOrg,
        string indexed moduleKey,
        address indexed caller,
        bytes selfParams,
        bytes[] preHookParams,
        bytes[] postHookParams
    );

    /// @notice Emits when a module is configured for an IP Org.
    event ModuleConfigured(
        address indexed ipOrg,
        string indexed moduleKey,
        address indexed caller,
        bytes params
    );

    /// @notice Fetches the latest protocol module bound to a specific key.
    function protocolModule(string calldata moduleKey) external view returns (address);
}
