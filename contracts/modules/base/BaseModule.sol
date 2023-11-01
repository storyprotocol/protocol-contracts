// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { HookRegistry } from "./HookRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";

abstract contract BaseModule is IModule, HookRegistry {

    struct ModuleConstruction {
        address ipaRegistry;
        address moduleRegistry;
    }

    address public immutable IPA_REGISTRY;
    address public immutable MODULE_REGISTRY;

    constructor(ModuleConstruction memory params_) {
        if (params_.ipaRegistry == address(0)) {
            revert Errors.BaseModule_ZeroIpaRegistry();
        }
        IPA_REGISTRY = params_.ipaRegistry;
        if (params_.moduleRegistry == address(0)) {
            revert Errors.BaseModule_ZeroModuleRegistry();
        }
        MODULE_REGISTRY = params_.moduleRegistry;
    }

    // TODO access control on sender
    function execute(
        address caller_,
        bytes calldata selfParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external {
        _verifyExecution(caller_, selfParams_);
        if (!_executeHooks(preHookParams_, HookType.PreAction)) {
            emit RequestPending(caller_);
            return;
        }
        _performAction(caller_, selfParams_);
        _executeHooks(postHookParams_, HookType.PostAction);
        emit RequestCompleted(caller_);
    }

    // TODO access control on sender
    function configure(address caller_, bytes calldata params_) external {
        _configure(caller_, params_);
    }

    function _executeHooks(bytes[] calldata params_, HookRegistry.HookType hType_) virtual internal returns (bool) {
        address[] memory hooks = _hooksForType(hType_);
        uint256 hooksLength = hooks.length;
        if (params_.length != hooksLength) {
            revert Errors.BaseModule_HooksParamsLengthMismatch(uint8(hType_));
        }
        for (uint256 i = 0; i < hooksLength; i++) {
            // TODO: hook execution and return false if a hook returns false
        }
        return true;
    }

    function _hookRegistryAdmin() virtual override internal view returns (address);
    function _configure(address caller_, bytes calldata params_) virtual internal;
    function _verifyExecution(address caller_, bytes calldata params_) virtual internal {}
    function _performAction(address caller_, bytes calldata params_) virtual internal {}

}