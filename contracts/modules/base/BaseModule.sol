// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";
import { HookRegistry } from "./HookRegistry.sol";

abstract contract BaseModule is IModule, HookRegistry {

    struct ModuleConstruction {
        address ipaRegistry;
        address moduleRegistry;
    }

    address public immutable IPA_REGISTRY;
    address public immutable MODULE_REGISTRY;

    constructor(ModuleConstruction memory params) {
        IPA_REGISTRY = params.ipaRegistry;
        MODULE_REGISTRY = params.moduleRegistry;
    }

    function execute(bytes calldata selfParams, bytes[] calldata preHookParams, bytes[] calldata postHookParams) external {
        // Should we include a request Id?
        _verifyExecution(msg.sender, selfParams);
        if (!_executePreHooks(preHookParams)) {
            emit RequestPending(msg.sender);
            return;
        }
        _performAction(selfParams);
        _executePostHooks(postHookParams);
        emit RequestCompleted(msg.sender);
    }

    function _hookRegistryAdmin() virtual override internal view returns (address) {
        // get owner from ipa registry
    }

    function _verifyExecution(address caller, bytes calldata selfParams) virtual internal {}
    function _executePreHooks(bytes[] calldata params) virtual internal returns (bool) {}
    function _performAction(bytes calldata params) virtual internal {}
    function _executePostHooks(bytes[] calldata params) virtual internal {}

}