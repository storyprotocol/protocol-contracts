// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { HookRegistry } from "./HookRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";

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
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata selfParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external {
        _verifyExecution(ipOrg_, caller_, selfParams_);
        if (!_executeHooks(preHookParams_, HookType.PreAction)) {
            emit RequestPending(caller_);
            return;
        }
        _performAction(ipOrg_, caller_, selfParams_);
        _executeHooks(postHookParams_, HookType.PostAction);
        emit RequestCompleted(caller_);
    }

    // TODO access control on sender
    function configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) external {
        _configure(ipOrg_, caller_, params_);
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
    function _configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual internal;
    function _verifyExecution(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual internal {}
    function _performAction(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual internal {}

}