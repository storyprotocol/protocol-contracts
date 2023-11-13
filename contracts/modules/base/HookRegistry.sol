// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";

abstract contract HookRegistry {
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

    event HooksRegistered(HookType indexed hType, bytes32 indexed registryKey, address[] indexed hook);
    event HooksCleared(HookType indexed hType, bytes32 indexed registryKey);
    
    modifier onlyHookRegistryAdmin() {
        if (msg.sender != _hookRegistryAdmin())
            revert Errors.HookRegistry_CallerNotAdmin();
        _;
    }

    function registerHooks(
        HookType hType_,
        bytes32 registryKey_,
        address[] calldata hooks_,
        bytes[] calldata hooksConfig_
    ) public onlyHookRegistryAdmin {
        clearHooks(hType_, registryKey_);
        _registerHooks(
            _hooksForType(hType_, registryKey_),
            _hooksConfigForType(hType_, registryKey_),
            hooks_,
            hooksConfig_
        );
        emit HooksRegistered(hType_, registryKey_, hooks_);
    }

    function isRegistered(
        HookType hType_,
        bytes32 registryKey_,
        address hook_
    ) external view returns (bool) {
        return hookIndex(hType_, registryKey_, hook_) != INDEX_NOT_FOUND;
    }

    function hookAt(
        HookType hType_,
        bytes32 registryKey_,
        uint256 index_
    ) external view returns (address) {
        address[] memory hooks = _hooksForType(hType_, registryKey_);
        if (index_ >= hooks.length) {
            revert Errors.HookRegistry_IndexOutOfBounds(index_);
        }
        return _hooksForType(hType_, registryKey_)[index_];
    }

    function hookConfigAt(
        HookType hType_,
        bytes32 registryKey_,
        uint256 index_
    ) external view returns (bytes memory) {
        bytes[] memory hooksConfig = _hooksConfigForType(hType_, registryKey_);
        if (index_ >= hooksConfig.length) {
            revert Errors.HookRegistry_IndexOutOfBounds(index_);
        }
        return _hooksConfigForType(hType_, registryKey_)[index_];
    }

    function totalHooks(
        HookType hType_,
        bytes32 registryKey_
    ) external view returns (uint256) {
        return _hooksForType(hType_, registryKey_).length;
    }

    function totalHooksConfig(
        HookType hType_,
        bytes32 registryKey_
    ) external view returns (uint256) {
        return _hooksConfigForType(hType_, registryKey_).length;
    }
    
    function clearHooks(
        HookType hType_,
        bytes32 registryKey_
    ) public onlyHookRegistryAdmin {
        if (hType_ == HookType.PreAction && _preActionHooks[registryKey_].length > 0) {
            delete _preActionHooks[registryKey_];
            delete _preActionHooksConfig[registryKey_];
        } else if (_postActionHooks[registryKey_].length > 0) {
            delete _postActionHooks[registryKey_];
            delete _postActionHooksConfig[registryKey_];
        }
        emit HooksCleared(hType_, registryKey_);
    }

    function hookIndex(
        HookType hType_,
        bytes32 registryKey_,
        address hook_
    ) public view returns (uint256) {
        return _hookIndex(_hooksForType(hType_, registryKey_), hook_);
    }

    function _hookRegistryAdmin() internal view virtual returns (address);

    function _hooksForType(
        HookType hType_,
        bytes32 registryKey_
    ) internal view returns (address[] storage) {
        if (hType_ == HookType.PreAction) {
            return _preActionHooks[registryKey_];
        } else {
            return _postActionHooks[registryKey_];
        }
    }

    function _hooksConfigForType(
        HookType hType_,
        bytes32 registryKey_
    ) internal view returns (bytes[] storage) {
        if (hType_ == HookType.PreAction) {
            return _preActionHooksConfig[registryKey_];
        } else {
            return _postActionHooksConfig[registryKey_];
        }
    }

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
                IHook(newHooks_[i]).validateConfig(newHooksConfig_[i]);
                hooks_.push(newHooks_[i]);
                hooksConfig_.push(newHooksConfig_[i]);
            }
        }
    }

    function _hookIndex(
        address[] storage hooks,
        address hook_
    ) private view returns (uint256) {
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
