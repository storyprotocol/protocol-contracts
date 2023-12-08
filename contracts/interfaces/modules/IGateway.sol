// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ModuleDependencies } from "contracts/lib/modules/Module.sol";

/// @title Module Gateway Interface
/// @notice Interface for a Story Protocol module gateway, which is a contract
///         that may be granted access by the module registry to call module
///         functions declared by the gateway's module dependency set.
interface IGateway {
    /// @notice Synchronizes all downstream dependencies via the module registry.
    /// @dev This function may only be called by the module registry.
    /// @return dependencies The freshly updated dependencies needed by the gateway.
    function updateDependencies() external returns (ModuleDependencies memory dependencies);

    /// @notice Fetches all module dependencies required by the gateway contract.
    /// @return dependencies The dependencies that the gateway requires from the protocol.
    function getDependencies() external view returns (ModuleDependencies memory dependencies);
}
