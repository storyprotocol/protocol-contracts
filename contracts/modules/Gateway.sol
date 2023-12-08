// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { Errors } from "contracts/lib/Errors.sol";
import { IGateway } from "contracts/interfaces/modules/IGateway.sol";
import { ModuleDependencies } from "contracts/lib/modules/Module.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";

/// @title Module Gateway
/// @notice This contract serves as the base layer all module "frontends" must
///         extend. Protocol admins enroll gateways through the module registry,
///         which give them access to call all module functions listed as part
///         of their dependency set.
abstract contract Gateway is IGateway {
    bool public registered;

    ModuleRegistry public immutable MODULE_REGISTRY;

    /// @notice Modifier that restricts the caller to only the module registry.
    modifier onlyModuleRegistry() {
        if (msg.sender != address(MODULE_REGISTRY)) {
            revert Errors.BaseModule_OnlyModuleRegistry();
        }
        _;
    }

    constructor(ModuleRegistry moduleRegistry_) {
        MODULE_REGISTRY = moduleRegistry_;
    }

    /// @notice Synchronizes all downstream dependencies via the module registry.
    function updateDependencies() external virtual override returns (ModuleDependencies memory dependencies);

    /// @notice Fetches all module dependencies required by the gateway contract.
    function getDependencies() external view virtual override returns (ModuleDependencies memory dependencies);
}
