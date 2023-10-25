// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { HookRegistry } from "./HookRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";

abstract contract BaseModule is IModule, HookRegistry {

    struct ModuleConstruction {
        address ipaRegistry;
        address moduleRegistry;
    }

    address public immutable IPA_REGISTRY;
    address public immutable MODULE_REGISTRY;

    modifier onlyModuleRegistry() {
        // TODO: Enforce this
        // if (msg.sender != MODULE_REGISTRY) 
        //    revert Errors.BaseModule_CallerNotModuleRegistry();
        _;
    }

    constructor(ModuleConstruction memory params) {
        IPA_REGISTRY = params.ipaRegistry;
        MODULE_REGISTRY = params.moduleRegistry;
    }

    function execute(
        address caller,
        bytes calldata selfParams,
        bytes[] calldata preHookParams,
        bytes[] calldata postHookParams
    ) external onlyModuleRegistry {
        _verifyExecution(caller, selfParams);
        if (!_executePreHooks(preHookParams)) {
            emit RequestPending(caller);
            return;
        }
        _performAction(selfParams);
        _executePostHooks(postHookParams);
        emit RequestCompleted(caller);
    }

    function configure(bytes calldata params) external onlyModuleRegistry {
        _configure(msg.sender, params);
    }

    function _hookRegistryAdmin() virtual override internal view returns (address);
    function _configure(address caller, bytes calldata params) virtual internal;
    function _verifyExecution(address caller, bytes calldata selfParams) virtual internal {}
    function _executePreHooks(bytes[] calldata params) virtual internal returns (bool) {}
    function _performAction(bytes calldata params) virtual internal {}
    function _executePostHooks(bytes[] calldata params) virtual internal {}

}