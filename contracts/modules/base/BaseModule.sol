// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { IHook, HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import { HookRegistry } from "./HookRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrgController } from "contracts/ip-org/IPOrgController.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { LicenseRegistry } from "contracts/modules/licensing/LicenseRegistry.sol";

/// @title BaseModule
/// @notice Base implementation for all modules in Story Protocol. This is meant to ensure
/// that all modules follow the same execution flow and have access to hooks.
/// It's up to the module how to perform the actions, verifications and authorizations.
/// @dev This contract should NOT have state in storage, in order to have upgradeable or non-upgradeable
/// modules.
abstract contract BaseModule is IModule, HookRegistry {
    struct ModuleConstruction {
        IPAssetRegistry ipaRegistry;
        ModuleRegistry moduleRegistry;
        LicenseRegistry licenseRegistry;
        IPOrgController ipOrgController;
    }

    IPAssetRegistry public immutable IPA_REGISTRY;
    ModuleRegistry public immutable MODULE_REGISTRY;
    LicenseRegistry public immutable LICENSE_REGISTRY;
    IPOrgController public immutable IP_ORG_CONTROLLER;

    modifier onlyModuleRegistry() {
        if (msg.sender != address(MODULE_REGISTRY)) {
            revert Errors.BaseModule_OnlyModuleRegistry();
        }
        _;
    }

    constructor(ModuleConstruction memory params_) {
        if (address(params_.ipaRegistry) == address(0)) {
            revert Errors.BaseModule_ZeroIpaRegistry();
        }
        IPA_REGISTRY = params_.ipaRegistry;
        if (address(params_.moduleRegistry) == address(0)) {
            revert Errors.BaseModule_ZeroModuleRegistry();
        }
        MODULE_REGISTRY = params_.moduleRegistry;
        if (address(params_.licenseRegistry) == address(0)) {
            revert Errors.BaseModule_ZeroLicenseRegistry();
        }
        LICENSE_REGISTRY = params_.licenseRegistry;
        IP_ORG_CONTROLLER = params_.ipOrgController;
    }

    /// Main execution entrypoint. It will verify params, execute pre action hooks, perform the action,
    /// execute post action hooks and emit the RequestCompleted event, plus returning the result.
    /// It's up to the module to decode and encode params appropriately.
    /// @param ipOrg_ address of the IPOrg or zero address 
    /// @param caller_ address requesting the execution
    /// @param moduleParams_ encoded params for module action
    /// @param preHookParams_ encoded params for pre action hooks
    /// @param postHookParams_ encoded params for post action hooks
    function execute(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata moduleParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external onlyModuleRegistry returns (bytes memory result) {
        _verifyExecution(ipOrg_, caller_, moduleParams_);
        bytes32 registryKey = _hookRegistryKey(ipOrg_, caller_, moduleParams_);
        if (!_executeHooks(preHookParams_, HookType.PreAction, registryKey)) {
            emit RequestPending(caller_);
            return "";
        }
        result = _performAction(ipOrg_, caller_, moduleParams_);
        _executeHooks(postHookParams_, HookType.PostAction, registryKey);
        emit RequestCompleted(caller_);
        return result;
    }

    /// Configuration entrypoint. It's up to the module to decode params appropriately.
    /// @param ipOrg_ address of the IPOrg or zero address 
    /// @param caller_ address requesting the execution
    /// @param params_ encoded configuration params
    function configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) onlyModuleRegistry external returns (bytes memory) {
        return _configure(ipOrg_, caller_, params_);
    }

    function _executeHooks(
        bytes[] calldata params_,
        HookRegistry.HookType hType_,
        bytes32 registryKey_
    ) virtual internal returns (bool) {
        address[] memory hooks = _hooksForType(hType_, registryKey_);
        bytes[] memory hooksConfig = _hooksConfigForType(hType_, registryKey_);
        uint256 hooksLength = hooks.length;
        if (params_.length != hooksLength) {
            revert Errors.BaseModule_HooksParamsLengthMismatch(uint8(hType_));
        }
        for (uint256 i = 0; i < hooksLength; i++) {
            if (!_executeHook(hType_, hooks[i], hooksConfig[i], params_[i])) {
                return false;
            }
        }
        return true;
    }

    /// @dev Executes a hook.
    /// This function should be overridden in derived contracts if they need to support Async hooks.
    /// @param hook The address of the hook.
    /// @param hookConfig_ The configuration of the hook.
    /// @param hookParams_ The parameters of the hook.
    /// @return True if the hook execution is completed, false otherwise.
    function _executeHook(
        HookRegistry.HookType,
        address hook,
        bytes memory hookConfig_,
        bytes memory hookParams_
    ) internal virtual returns (bool) {
        Hook.ExecutionContext memory context = Hook.ExecutionContext({
            config: hookConfig_,
            params: hookParams_
        });
        HookResult result;
        (result,) = IHook(hook).executeSync(abi.encode(context));
        return result == HookResult.Completed;
    }

    function _configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual internal returns (bytes memory);
    function _verifyExecution(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual internal {}
    function _performAction(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual internal returns (bytes memory result) {}
    
    /// @dev Generates a registry key based on module execution parameters.
    /// This function should be overridden in derived contracts to provide the actual logic for generating the registry key.
    /// @param ipOrg_ The address of the IPOrg.
    /// @param caller_ The address requesting the execution.
    /// @param params_ The encoded parameters for module action.
    /// @return The generated registry key.
    function _hookRegistryKey(IIPOrg ipOrg_, address caller_, bytes calldata params_) internal view virtual returns(bytes32);
}
