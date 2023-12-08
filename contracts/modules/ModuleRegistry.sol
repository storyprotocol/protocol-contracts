// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { IModuleRegistry } from "contracts/interfaces/modules/IModuleRegistry.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { IGateway } from "contracts/interfaces/modules/IGateway.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { ModuleKey, ModuleDependencies, toModuleKey } from "contracts/lib/modules/Module.sol";

/// @title ModuleRegistry
/// @notice The module registry serves as the global repository for all modules
///         registered under Story Protocol, and acts as the central authorization
///         mechanism for configuring which frontends may call which modules.
contract ModuleRegistry is IModuleRegistry, AccessControlled, Multicall {
    /// @notice Identifying protocol-wide modules (opposed to those bound to specific IP Orgs).
    address public constant PROTOCOL_LEVEL = address(0);

    /// @dev Maps protocol hook string keys to their respective hooks.
    mapping(string => IHook) internal _protocolHooks;

    /// @dev Maps hook contracts to their respective hook key names.
    mapping(IHook => string) internal _hookKeys;

    /// @notice Maps module keys to their respective modules.
    mapping(ModuleKey => address) internal _modules;

    /// @notice Tracks whether a gateway can call a specific module function.
    mapping(ModuleKey => mapping(IGateway => mapping(bytes4 => bool))) internal _isAuthorized;

    constructor(address accessControl_) AccessControlled(accessControl_) {}

    /// @notice Gets the protocol-wide module associated with a module key.
    /// @param key_ The unique module key used to identify the module.
    function protocolModule(string calldata key_) public view returns (address) {
        return _modules[toModuleKey(key_)];
    }

    /// @notice Gets the protocol-wide module associated with a module key.
    /// @param key_ The unique module key used to identify the module.
    function protocolModule(ModuleKey key_) public view returns (address) {
        return _modules[key_];
    }

    /// @notice Checks whether a gateway is authorized to call a module function.
    /// @param key_ The type of the module being checked.
    /// @param gateway_ The gateway which has the module function as a dependency.
    /// @param fn_ The module function whose access is being checked for.
    function isAuthorized(ModuleKey key_, IGateway gateway_, bytes4 fn_) public view returns (bool) {
        if (_modules[key_] == address(0)) {
            revert Errors.ModuleRegistry_ModuleNotYetRegistered();
        }
        return _isAuthorized[key_][gateway_][fn_];
    }

    /// @notice Registers a new gateway to the protocol with its declared dependencies.
    /// @dev This is only callable by entities with the MODULE_REGISTRAR_ROLE role.
    /// @param gateway_ The gateway being registered into the protocol.
    function registerProtocolGateway(IGateway gateway_) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        ModuleDependencies memory dependencies = gateway_.updateDependencies();
        uint256 numModules = dependencies.keys.length;
        if (numModules != dependencies.fns.length) {
            revert Errors.ModuleRegistry_InvalidGateway();
        }

        for (uint256 i = 0; i < numModules; ++i) {
            ModuleKey moduleKey = dependencies.keys[i];
            bytes4[] memory fns = dependencies.fns[i];

            if (_modules[moduleKey] == address(0)) {
                revert Errors.ModuleRegistry_ModuleNotYetRegistered();
            }

            // Authorize all module function dependencies for the gateway.
            for (uint256 j = 0; j < fns.length; j++) {
                if (_isAuthorized[moduleKey][gateway_][fns[j]]) {
                    revert Errors.ModuleRegistry_DependencyAlreadyRegistered();
                }
                _isAuthorized[moduleKey][gateway_][fns[j]] = true;
                emit ModuleAuthorizationGranted(moduleKey, fns[j], address(gateway_), true);
            }
        }
    }

    /// @notice Removes a gatway as an authorized caller of the protocol.
    /// @dev This is only callable by entities with the MODULE_REGISTRAR_ROLE role.
    /// @param gateway_ The gateway being removed from the protocol.
    function removeProtocolGateway(IGateway gateway_) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        ModuleDependencies memory dependencies = gateway_.getDependencies();
        uint256 numModules = dependencies.keys.length;
        if (numModules != dependencies.fns.length) {
            revert Errors.ModuleRegistry_InvalidGateway();
        }

        for (uint256 i = 0; i < numModules; ++i) {
            ModuleKey moduleKey = dependencies.keys[i];
            bytes4[] memory fns = dependencies.fns[i];

            // Revoke authorizations made previously.
            // TODO: Change logic to track dependencies through the registry itself.
            for (uint256 j = 0; j < fns.length; j++) {
                if (!_isAuthorized[moduleKey][gateway_][fns[j]]) {
                    revert Errors.ModuleRegistry_DependencyNotYetRegistered();
                }
                _isAuthorized[moduleKey][gateway_][fns[j]] = false;
                emit ModuleAuthorizationGranted(moduleKey, fns[j], address(gateway_), false);
            }
        }
    }

    /// @notice Adds a new module to the protocol.
    /// @dev This is only callable by entities with the MODULE_REGISTRAR_ROLE role.
    /// @param key_ The identifier for the type of module being enrolled.
    /// @param module_ The module that will be registered into the protocol.
    function registerProtocolModule(
        ModuleKey key_,
        IModule module_
    ) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        if (address(module_) == address(0)) {
            revert Errors.ZeroAddress();
        }

        if (_modules[key_] != address(0)) {
            revert Errors.ModuleRegistry_ModuleAlreadyRegistered();
        }

        if (module_.moduleKey() != key_) {
            revert Errors.ModuleRegistry_ModuleKeyMismatch();
        }

        _modules[key_] = address(module_);

        emit ModuleAdded(PROTOCOL_LEVEL, string(abi.encodePacked(key_)), address(module_));
    }

    /// @notice Registers a new protocol hook.
    /// @param hookKey The unique identifier for the hook.
    /// @param hookAddress The address of the hook contract.
    /// @dev This function can only be called by an account with the MODULE_REGISTRAR_ROLE.
    function registerProtocolHook(
        string calldata hookKey,
        IHook hookAddress
    ) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        if (address(hookAddress) == address(0)) {
            revert Errors.ZeroAddress();
        }
        _protocolHooks[hookKey] = hookAddress;
        _hookKeys[hookAddress] = hookKey;
        emit HookAdded(PROTOCOL_LEVEL, hookKey, address(hookAddress));
    }

    /// @notice Removes a protocol hook.
    /// @param hookKey The unique identifier for the hook.
    /// @dev This function can only be called by an account with the MODULE_REGISTRAR_ROLE.
    /// If the hook is not registered, it reverts with an error.
    function removeProtocolHook(string calldata hookKey) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        if (address(_protocolHooks[hookKey]) == address(0)) {
            revert Errors.ModuleRegistry_HookNotRegistered(hookKey);
        }
        IHook hookAddress = _protocolHooks[hookKey];
        delete _protocolHooks[hookKey];
        delete _hookKeys[hookAddress];
        emit HookRemoved(PROTOCOL_LEVEL, hookKey, address(hookAddress));
    }

    /// Removes the current module configured for a module key.
    /// This is only callable by MODULE_REGISTRAR_ROLE holders.
    /// @param key_ The identifier for the type of module being removed.
    function removeProtocolModule(ModuleKey key_) external onlyRole(AccessControl.MODULE_REGISTRAR_ROLE) {
        if (_modules[key_] == address(0)) {
            revert Errors.ModuleRegistry_ModuleNotYetRegistered();
        }

        address removedModule = _modules[key_];
        delete _modules[key_];

        emit ModuleRemoved(key_, removedModule);
    }

    /// @notice Returns the protocol hook associated with a given hook key.
    /// @param hookKey The unique identifier for the hook.
    /// @return The protocol hook associated with the given hook key.
    function hookForKey(string calldata hookKey) external view returns (IHook) {
        return _protocolHooks[hookKey];
    }

    /// @notice Checks if a hook is registered in the protocol.
    /// @param hook_ The hook to check.
    /// @return True if the hook is registered, false otherwise.
    function isRegisteredHook(IHook hook_) external view returns (bool) {
        return address(_protocolHooks[_hookKeys[hook_]]) == address(hook_);
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
        bytes memory moduleParams_,
        bytes[] memory preHookParams_,
        bytes[] memory postHookParams_
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
    function configure(IIPOrg ipOrg_, string calldata moduleKey_, bytes calldata params_) external {
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
    ) external onlyRole(AccessControl.MODULE_EXECUTOR_ROLE) returns (bytes memory) {
        return _configure(ipOrg_, caller_, moduleKey_, params_);
    }

    /// @dev Executes an action for a specific module.
    /// @param ipOrg_ The IP Org under which the execution is performed.
    /// @param caller_ The address of the original calling entity.
    /// @param moduleKey_ The identifier of the module being executed.
    /// @param moduleParams_ Encoded data to be passed to the module.
    /// @param preHookParams_ Set of data to be used for any registered pre-hooks.
    /// @param postHookParams_ Set of data to be used for any registered post-hooks.
    function _execute(
        IIPOrg ipOrg_,
        address caller_,
        string calldata moduleKey_,
        bytes memory moduleParams_,
        bytes[] memory preHookParams_,
        bytes[] memory postHookParams_
    ) private returns (bytes memory result) {
        IModule module = IModule(_modules[toModuleKey(moduleKey_)]);
        if (address(module) == address(0)) {
            revert Errors.ModuleRegistry_ModuleNotYetRegistered();
        }
        result = module.execute(ipOrg_, caller_, moduleParams_, preHookParams_, postHookParams_);
        emit ModuleExecuted(address(ipOrg_), moduleKey_, caller_, moduleParams_, preHookParams_, postHookParams_);
        return result;
    }

    /// @dev Configures a specific module for an IP Org.
    /// @param ipOrg_ The IP Org making the relevant configurations.
    /// @param caller_ The address of the calling entity performing the configuration.
    /// @param moduleKey_ The identifier for the module being configured.
    /// @param params_ Module-specific data used for the configuration.
    function _configure(
        IIPOrg ipOrg_,
        address caller_,
        string calldata moduleKey_,
        bytes calldata params_
    ) private returns (bytes memory result) {
        IModule module = IModule(_modules[toModuleKey(moduleKey_)]);
        if (address(module) == address(0)) {
            revert Errors.ModuleRegistry_ModuleNotYetRegistered();
        }
        result = module.configure(ipOrg_, caller_, params_);
        emit ModuleConfigured(address(ipOrg_), moduleKey_, caller_, params_);
        return result;
    }
}
