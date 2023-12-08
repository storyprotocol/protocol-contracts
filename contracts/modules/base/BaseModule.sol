// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { IHook, HookResult } from "contracts/interfaces/hooks/base/IHook.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import { HookRegistry } from "./HookRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrgController } from "contracts/ip-org/IPOrgController.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { Gateway } from "contracts/modules/Gateway.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { LicenseRegistry } from "contracts/modules/licensing/LicenseRegistry.sol";
import { ICallbackHandler } from "contracts/interfaces/hooks/base/ICallbackHandler.sol";
import { IERC165, ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ModuleKey } from "contracts/lib/modules/Module.sol";

/// @title BaseModule
/// @notice Base implementation for all modules in Story Protocol. This is meant to ensure
/// that all modules follow the same execution flow and have access to hooks.
/// It's up to the module how to perform the actions, verifications and authorizations.
/// @dev This contract should NOT have state in storage, in order to have upgradeable or non-upgradeable
/// modules.
abstract contract BaseModule is ERC165, IModule, ICallbackHandler, HookRegistry {
    using Hook for IHook;

    struct ModuleConstruction {
        IPAssetRegistry ipaRegistry;
        ModuleRegistry moduleRegistry;
        LicenseRegistry licenseRegistry;
        IPOrgController ipOrgController;
    }

    struct ModuleExecutionContext {
        IIPOrg ipOrg;
        address caller;
        bytes moduleParams;
        bytes[] preHookParams;
        bytes[] postHookParams;
        bytes32 hookRegistryKey;
        HookType executionHookType;
        uint256 hookPosition;
    }

    IPAssetRegistry public immutable IPA_REGISTRY;
    LicenseRegistry public immutable LICENSE_REGISTRY;
    IPOrgController public immutable IP_ORG_CONTROLLER;

    /// @notice used to store the context of an async hook execution.
    /// @dev The execution of the module is pending, and will need to be executed again.
    mapping(bytes32 => ModuleExecutionContext) private _asyncContexts;

    /// @notice Modifier for authorizing the calling entity.
    modifier onlyAuthorized() {
        _authenticate();
        _;
    }

    modifier onlyModuleRegistry() {
        if (msg.sender != address(MODULE_REGISTRY)) {
            revert Errors.BaseModule_OnlyModuleRegistry();
        }
        _;
    }

    constructor(ModuleConstruction memory params_) HookRegistry(params_.moduleRegistry) {
        if (address(params_.ipaRegistry) == address(0)) {
            revert Errors.BaseModule_ZeroIpaRegistry();
        }
        IPA_REGISTRY = params_.ipaRegistry;
        if (address(params_.licenseRegistry) == address(0)) {
            revert Errors.BaseModule_ZeroLicenseRegistry();
        }
        LICENSE_REGISTRY = params_.licenseRegistry;
        IP_ORG_CONTROLLER = params_.ipOrgController;
    }

    /// @notice Gets the protocol-wide key associated with the module.
    /// @return The string identifier of the module.
    function moduleKey() public pure virtual override returns (ModuleKey);

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
        ModuleExecutionContext memory context = ModuleExecutionContext({
            ipOrg: ipOrg_,
            caller: caller_,
            moduleParams: moduleParams_,
            preHookParams: preHookParams_,
            postHookParams: postHookParams_,
            hookRegistryKey: registryKey,
            executionHookType: HookType.PreAction,
            hookPosition: 0
        });
        return _execute(context);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(ICallbackHandler).interfaceId ||
            interfaceId == type(IModule).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Executes the module with the provided parameters.
    /// @dev This function handles the execution logic for the module.
    ///      It also will be used by ayhnc hooks to continue the execution of the module.
    /// @param context_ The execution context which includes all the parameters for the module execution.
    /// @return result The result of the execution in bytes format.
    function _execute(ModuleExecutionContext memory context_) internal returns (bytes memory result) {
        if (context_.executionHookType == HookType.PreAction && !_executeHooks(context_)) {
            emit RequestPending(context_.caller);
            return "";
        }
        result = _performAction(context_.ipOrg, context_.caller, context_.moduleParams);
        context_.executionHookType = HookType.PostAction;
        context_.hookPosition = 0;
        _executeHooks(context_);
        emit RequestCompleted(context_.caller);
        return result;
    }

    /// Configuration entrypoint. It's up to the module to decode params appropriately.
    /// @param ipOrg_ address of the IPOrg or zero address
    /// @param caller_ address requesting the execution
    /// @param params_ encoded configuration params
    function configure(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) external onlyModuleRegistry returns (bytes memory) {
        return _configure(ipOrg_, caller_, params_);
    }

    function _executeHooks(ModuleExecutionContext memory context_) internal virtual returns (bool) {
        address[] memory hooks = _hooksForType(context_.executionHookType, context_.hookRegistryKey);
        bytes[] memory hooksConfig = _hooksConfigForType(context_.executionHookType, context_.hookRegistryKey);
        uint256 hooksLength = hooks.length;
        bytes[] memory hookParams = context_.executionHookType == HookType.PreAction
            ? context_.preHookParams
            : context_.postHookParams;
        if (hookParams.length != hooksLength) {
            revert Errors.BaseModule_HooksParamsLengthMismatch(uint8(context_.executionHookType));
        }
        // Continue to execute each hook from the current executing position in the hook list.
        for (uint256 i = context_.hookPosition; i < hooksLength; i++) {
            // make sure the hook executing postion is updated in the context
            context_.hookPosition = i;
            Hook.ExecutionContext memory hookContext = Hook.ExecutionContext({
                config: hooksConfig[i],
                params: hookParams[i]
            });
            // check hook type, if async, call executeAsync, otherwise call executeSync
            HookResult result;
            if (IHook(hooks[i]).canSupportSyncCall()) {
                (result, ) = IHook(hooks[i]).executeSync(abi.encode(hookContext));
            } else {
                result = _executeAsyncHook(hooks[i], hookContext, context_);
            }
            // means the hook execution is pending
            if (result != HookResult.Completed) return false;
        }
        return true;
    }

    function _configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) internal virtual returns (bytes memory);

    function _verifyExecution(IIPOrg ipOrg_, address caller_, bytes calldata params_) internal virtual {}

    function _performAction(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) internal virtual returns (bytes memory result) {}

    /// @notice Authenticates the caller entity through the module registry.
    function _authenticate() internal view {
        if (!MODULE_REGISTRY.isAuthorized(moduleKey(), Gateway(msg.sender), msg.sig)) {
            revert Errors.BaseModule_Unauthorized();
        }
    }

    /// @dev Generates a registry key based on module execution parameters.
    /// This function should be overridden in derived contracts to provide actual logic for generating the registry key.
    /// @param ipOrg_ The address of the IPOrg.
    /// @param caller_ The address requesting the execution.
    /// @param params_ The encoded parameters for module action.
    /// @return The generated registry key.
    function _hookRegistryKey(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) internal view virtual returns (bytes32);

    function _executeAsyncHook(
        address hook_,
        Hook.ExecutionContext memory hookContext_,
        ModuleExecutionContext memory moduleContext_
    ) internal virtual returns (HookResult) {
        (HookResult result, , bytes32 requestId) = IHook(hook_).executeAsync(abi.encode(hookContext_), address(this));
        // only store the context if the hook is async
        if (result == HookResult.Pending) {
            _asyncContexts[requestId] = moduleContext_;
        }
        return result;
    }

    /// @notice Handles the callback from the asynchronous hook.
    /// @dev This function is called by the external service when the asynchronous hook is completed.
    /// @param requestId_ The ID of the request.
    /// @param callbackData_ The data returned by the callback.
    function handleHookCallback(bytes32 requestId_, bytes calldata callbackData_) external virtual override {
        (bool isPass, string memory errorMsg) = abi.decode(callbackData_, (bool, string));

        if (isPass) {
            _asyncContexts[requestId_].hookPosition++;
            _execute(_asyncContexts[requestId_]);
        } else {
            emit RequestFailed(_asyncContexts[requestId_].caller, errorMsg);
        }
        delete _asyncContexts[requestId_];
    }
}
