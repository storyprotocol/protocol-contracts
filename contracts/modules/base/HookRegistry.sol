// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";

abstract contract HookRegistry {
    enum HookType {
        PreAction,
        PostAction
    }

    address[] public preActionHooks;
    address[] public postActionHooks;

    uint256 public constant INDEX_NOT_FOUND = type(uint256).max;
    uint256 public constant MAX_HOOKS = 10;

    event HookRegistered(HookType hType, address indexed hook, uint256 index);
    event HookUnregistered(HookType hType, address indexed hook, uint256 index);
    event HookReplaced(
        HookType hType,
        address indexed prevHook,
        uint256 prevIndex,
        address indexed nextHook,
        uint256 nextIndex
    );

    modifier onlyHookRegistryAdmin() {
        if (msg.sender == _hookRegistryAdmin())
            revert Errors.HookRegistry_CallerNotAdmin();
        _;
    }

    function registerHook(
        HookType hType_,
        address hook_
    ) external onlyHookRegistryAdmin {
        emit HookRegistered(
            hType_,
            hook_,
            _registerHook(_hooksForType(hType_), hook_)
        );
    }

    function unregisterHook(
        HookType hType_,
        address hook
    ) external onlyHookRegistryAdmin {
        emit HookUnregistered(
            hType_,
            hook,
            _unregisterHook(_hooksForType(hType_), hook)
        );
    }

    function replaceHook(
        HookType hType_,
        uint256 prevIndex_,
        uint256 nextIndex_
    ) external onlyHookRegistryAdmin {
        (address prevHook, address nextHook) = _replaceHook(
            _hooksForType(hType_),
            prevIndex_,
            nextIndex_
        );
        emit HookReplaced(hType_, prevHook, prevIndex_, nextHook, nextIndex_);
    }

    function hookIndex(
        HookType hType_,
        address hook_
    ) public view returns (uint256) {
        return _hookIndex(_hooksForType(hType_), hook_);
    }

    function isRegistered(
        HookType hType_,
        address hook_
    ) public view returns (bool) {
        return hookIndex(hType_, hook_) != INDEX_NOT_FOUND;
    }

    function _hookRegistryAdmin() internal view virtual returns (address);

    function _hooksForType(
        HookType hType_
    ) private view returns (address[] storage) {
        if (hType_ == HookType.PreAction) {
            return preActionHooks;
        } else {
            return postActionHooks;
        }
    }

    function _registerHook(
        address[] storage hooks_,
        address hook_
    ) private returns (uint256) {
        if (_hookIndex(hooks_, hook_) != INDEX_NOT_FOUND) {
            revert("HookRegistry: hook already registered");
        }
        hooks_.push(hook_);
        return hooks_.length - 1;
    }

    function _unregisterHook(
        address[] storage hooks_,
        address hook_
    ) private returns (uint256) {
        uint256 index = _hookIndex(hooks_, hook_);
        if (index == INDEX_NOT_FOUND) {
            revert Errors.HookRegistry_HookNotFound();
        }
        delete hooks_[index];
        return index;
    }

    function _replaceHook(
        address[] storage hooks_,
        uint256 prevIndex_,
        uint256 nextIndex_
    ) private returns (address prevHook, address nextHook) {
        if (prevIndex_ >= hooks_.length || nextIndex_ >= hooks_.length) {
            revert Errors.HookRegistry_IndexOutOfBounds();
        }
        prevHook = hooks_[prevIndex_];
        nextHook = hooks_[nextIndex_];
        hooks_[prevIndex_] = nextHook;
        hooks_[nextIndex_] = prevHook;
        return (prevHook, nextHook);
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
