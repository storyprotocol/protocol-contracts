// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";

abstract contract HookRegistry {
    enum HookType {
        PreAction,
        PostAction
    }

    address[] private _preActionHooks;
    address[] private _postActionHooks;

    uint256 public constant INDEX_NOT_FOUND = type(uint256).max;
    uint256 public constant MAX_HOOKS = 10;

    event HooksRegistered(HookType indexed hType, address[] indexed hook);
    event HooksCleared(HookType indexed hType);
    
    modifier onlyHookRegistryAdmin() {
        if (msg.sender != _hookRegistryAdmin())
            revert Errors.HookRegistry_CallerNotAdmin();
        _;
    }

    function registerHooks(
        HookType hType_,
        address[] calldata hooks_
    ) external onlyHookRegistryAdmin {
        clearHooks(hType_);
        _registerHooks(_hooksForType(hType_), hooks_);
        emit HooksRegistered(hType_, hooks_);
    }

    function isRegistered(
        HookType hType_,
        address hook_
    ) external view returns (bool) {
        return hookIndex(hType_, hook_) != INDEX_NOT_FOUND;
    }

    function hookAt(
        HookType hType_,
        uint256 index_
    ) external view returns (address) {
        return _hooksForType(hType_)[index_];
    }

    function totalHooks(
        HookType hType_
    ) external view returns (uint256) {
        return _hooksForType(hType_).length;
    }
    
    function clearHooks(
        HookType hType_
    ) public onlyHookRegistryAdmin {
        if (hType_ == HookType.PreAction && _preActionHooks.length > 0) {
            delete _preActionHooks;
        } else if (_postActionHooks.length > 0) {
            delete _postActionHooks;
        }
        emit HooksCleared(hType_);
    }

    function hookIndex(
        HookType hType_,
        address hook_
    ) public view returns (uint256) {
        return _hookIndex(_hooksForType(hType_), hook_);
    }

    function _hookRegistryAdmin() internal view virtual returns (address);

    function _hooksForType(
        HookType hType_
    ) private view returns (address[] storage) {
        if (hType_ == HookType.PreAction) {
            return _preActionHooks;
        } else {
            return _postActionHooks;
        }
    }

    function _registerHooks(
        address[] storage hooks_,
        address[] memory newHooks_
    ) private {
        uint256 newLength = newHooks_.length;
        if (newLength > MAX_HOOKS) {
            revert Errors.HookRegistry_MaxHooksExceeded();
        }
        unchecked {
            for (uint256 i = 0; i < newLength; i++) {
                if (newHooks_[i] == address(0)) {
                    revert Errors.HookRegistry_RegisteringZeroAddressHook();
                }
                if (i > 0 && newHooks_[i] == newHooks_[i - 1]) {
                    revert Errors.HookRegistry_RegisteringDuplicatedHook();
                }
                hooks_.push(newHooks_[i]);
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
