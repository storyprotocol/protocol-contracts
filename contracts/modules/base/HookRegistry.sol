// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Errors } from "contracts/lib/Errors.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";

/// @title HookRegistry
/// @notice This contract is an abstract contract that manages the registration of hooks.
/// Hooks are small pieces of code that are called before and after certain operations in the protocol.
/// @dev Each module that inherits from HookRegistry has its own local hook registry.
/// The HookRegistry supports multiple hook arrays, each associated with differentconfigs separated by a `registryKey`
/// Each module can define its own approach to generate its unique registryKey.
abstract contract HookRegistry {
    ModuleRegistry public immutable MODULE_REGISTRY;

    enum HookType {
        PreAction,
        PostAction
    }

    mapping(bytes32 => address[]) private _preActionHooks;
    mapping(bytes32 => address[]) private _postActionHooks;

    mapping(bytes32 => bytes[]) private _preActionHooksConfig;
    mapping(bytes32 => bytes[]) private _postActionHooksConfig;

    uint256 public constant INDEX_NOT_FOUND = type(uint256).max;
    uint256 public constant MAX_HOOKS = 10;

    event HooksRegistered(HookType indexed hType, bytes32 indexed registryKey, address[] hooks);
    event HooksCleared(HookType indexed hType, bytes32 indexed registryKey);

    /// @dev Modifier to check if the caller is the IPOrg owner.
    /// Reverts if the caller is not the IP Org owner.
    modifier onlyIpOrgOwner(IIPOrg ipOrg_) {
        if (address(ipOrg_) == address(0)) {
            revert Errors.ZeroAddress();
        }

        if (msg.sender != ipOrg_.owner()) revert Errors.HookRegistry_CallerNotIPOrgOwner();
        _;
    }

    constructor(ModuleRegistry moduleRegistry_) {
        if (address(moduleRegistry_) == address(0)) {
            revert Errors.HookRegistry_ZeroModuleRegistry();
        }
        MODULE_REGISTRY = moduleRegistry_;
    }

    /// @dev Registers hooks for a specific type and registry key.
    /// Clears any existing hooks for the same type and registry key.
    /// Emits a HooksRegistered event.
    /// Can only be called by the IP Org owner.
    /// @param hookType_ The type of the hooks to register.
    /// @param registryKey_ The registry key for the hooks.
    /// @param hooks_ The addresses of the hooks to register.
    /// @param hooksConfig_ The configurations for the hooks.
    function registerHooks(
        HookType hookType_,
        IIPOrg ipOrg_,
        bytes32 registryKey_,
        address[] calldata hooks_,
        bytes[] calldata hooksConfig_
    ) public onlyIpOrgOwner(ipOrg_) {
        clearHooks(hookType_, ipOrg_, registryKey_);
        _registerHooks(
            _hooksForType(hookType_, registryKey_),
            _hooksConfigForType(hookType_, registryKey_),
            hooks_,
            hooksConfig_
        );
        emit HooksRegistered(hookType_, registryKey_, hooks_);
    }

    /// @dev Checks if a hook is registered for a specific type and registry key.
    /// @param hookType_ The type of the hook.
    /// @param registryKey_ The registry key for the hook.
    /// @param hook_ The address of the hook.
    /// @return True if the hook is registered, false otherwise.
    function isRegistered(HookType hookType_, bytes32 registryKey_, address hook_) external view returns (bool) {
        return hookIndex(hookType_, registryKey_, hook_) != INDEX_NOT_FOUND;
    }

    /// @dev Returns the hook at a specific index for a specific type and registry key.
    /// Reverts if the index is out of bounds.
    /// @param hookType_ The type of the hook.
    /// @param registryKey_ The registry key for the hook.
    /// @param index_ The index of the hook.
    /// @return The address of the hook.
    function hookAt(HookType hookType_, bytes32 registryKey_, uint256 index_) external view returns (address) {
        address[] memory hooks = _hooksForType(hookType_, registryKey_);
        if (index_ >= hooks.length) {
            revert Errors.HookRegistry_IndexOutOfBounds(index_);
        }
        return _hooksForType(hookType_, registryKey_)[index_];
    }

    /// @dev Returns the hook configuration at a specific index for a specific type and registry key.
    /// Reverts if the index is out of bounds.
    /// @param hookType_ The type of the hook.
    /// @param registryKey_ The registry key for the hook.
    /// @param index_ The index of the hook.
    /// @return The configuration of the hook.
    function hookConfigAt(
        HookType hookType_,
        bytes32 registryKey_,
        uint256 index_
    ) external view returns (bytes memory) {
        bytes[] memory hooksConfig = _hooksConfigForType(hookType_, registryKey_);
        if (index_ >= hooksConfig.length) {
            revert Errors.HookRegistry_IndexOutOfBounds(index_);
        }
        return _hooksConfigForType(hookType_, registryKey_)[index_];
    }

    /// @dev Returns the total number of hooks for a specific type and registry key.
    /// @param hookType_ The type of the hooks.
    /// @param registryKey_ The registry key for the hooks.
    /// @return The total number of hooks.
    function totalHooks(HookType hookType_, bytes32 registryKey_) external view returns (uint256) {
        return _hooksForType(hookType_, registryKey_).length;
    }

    /// @dev Returns the total number of hook configurations for a specific type and registry key.
    /// @param hookType_ The type of the hooks.
    /// @param registryKey_ The registry key for the hooks.
    /// @return The total number of hook configurations.
    function totalHooksConfig(HookType hookType_, bytes32 registryKey_) external view returns (uint256) {
        return _hooksConfigForType(hookType_, registryKey_).length;
    }

    /// @dev Clears all hooks for a specific type and registry key.
    /// Emits a HooksCleared event.
    /// Can only be called by the IP Org owner.
    /// @param hookType_ The type of the hooks to clear.
    /// @param registryKey_ The registry key for the hooks.
    function clearHooks(HookType hookType_, IIPOrg ipOrg_, bytes32 registryKey_) public onlyIpOrgOwner(ipOrg_) {
        if (hookType_ == HookType.PreAction && _preActionHooks[registryKey_].length > 0) {
            delete _preActionHooks[registryKey_];
            delete _preActionHooksConfig[registryKey_];
        } else if (_postActionHooks[registryKey_].length > 0) {
            delete _postActionHooks[registryKey_];
            delete _postActionHooksConfig[registryKey_];
        }
        emit HooksCleared(hookType_, registryKey_);
    }

    /// @dev Returns the index of a hook for a specific type and registry key.
    /// @param hookType_ The type of the hook.
    /// @param registryKey_ The registry key for the hook.
    /// @param hook_ The address of the hook.
    /// @return The index of the hook. Returns INDEX_NOT_FOUND if the hook is not registered.
    function hookIndex(HookType hookType_, bytes32 registryKey_, address hook_) public view returns (uint256) {
        return _hookIndex(_hooksForType(hookType_, registryKey_), hook_);
    }

    /// @dev Returns the hooks for a specific type and registry key.
    /// @param hookType_ The type of the hooks.
    /// @param registryKey_ The registry key for the hooks.
    /// @return The array of hooks.
    function _hooksForType(HookType hookType_, bytes32 registryKey_) internal view returns (address[] storage) {
        if (hookType_ == HookType.PreAction) {
            return _preActionHooks[registryKey_];
        } else {
            return _postActionHooks[registryKey_];
        }
    }

    /// @dev Returns the hook configurations for a specific type and registry key.
    /// @param hookType_ The type of the hooks.
    /// @param registryKey_ The registry key for the hooks.
    /// @return The array of hook configurations.
    function _hooksConfigForType(HookType hookType_, bytes32 registryKey_) internal view returns (bytes[] storage) {
        if (hookType_ == HookType.PreAction) {
            return _preActionHooksConfig[registryKey_];
        } else {
            return _postActionHooksConfig[registryKey_];
        }
    }

    /// @dev Registers new hooks and their configurations.
    /// @param hooks_ The array of hooks to register.
    /// @param hooksConfig_ The array of hook configurations to register.
    /// @param newHooks_ The array of new hooks to register.
    /// @param newHooksConfig_ The array of new hook configurations to register.
    function _registerHooks(
        address[] storage hooks_,
        bytes[] storage hooksConfig_,
        address[] memory newHooks_,
        bytes[] memory newHooksConfig_
    ) private {
        uint256 newLength = newHooks_.length;
        if (newLength > MAX_HOOKS) {
            revert Errors.HookRegistry_MaxHooksExceeded();
        }
        if (newHooksConfig_.length != newLength) {
            revert Errors.HookRegistry_HooksConfigLengthMismatch();
        }
        unchecked {
            for (uint256 i = 0; i < newLength; i++) {
                if (newHooks_[i] == address(0)) {
                    revert Errors.HookRegistry_RegisteringZeroAddressHook();
                }
                if (i > 0 && newHooks_[i] == newHooks_[i - 1]) {
                    revert Errors.HookRegistry_RegisteringDuplicatedHook();
                }
                // only whitelisted hooks can be registered
                if (!MODULE_REGISTRY.isRegisteredHook(IHook(newHooks_[i]))) {
                    revert Errors.HookRegistry_RegisteringNonWhitelistedHook(newHooks_[i]);
                }
                IHook(newHooks_[i]).validateConfig(newHooksConfig_[i]);
                hooks_.push(newHooks_[i]);
                hooksConfig_.push(newHooksConfig_[i]);
            }
        }
    }

    /// @dev Returns the index of a hook in the array of hooks.
    /// @param hooks The array of hooks.
    /// @param hook_ The hook to find.
    /// @return The index of the hook. Returns INDEX_NOT_FOUND if the hook is not found.
    function _hookIndex(address[] storage hooks, address hook_) private view returns (uint256) {
        uint256 length = hooks.length;
        for (uint256 i = 0; i < length; ) {
            if (hooks[i] == hook_) {
                return i;
            }
            unchecked {
                i++;
            }
        }
        return INDEX_NOT_FOUND;
    }
}
