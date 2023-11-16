// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IModule } from "./IModule.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";

/// @title IModule
/// @notice Interface for a Story Protocol Module, building block of the protocol functionality.
interface IModule {

    /// The execution of the module is pending, and will need to be executed again.
    event RequestPending(address indexed sender);
    /// Module execution completed successfully.
    event RequestCompleted(address indexed sender);

    /// @notice Main execution entrypoint.
    /// @dev It will verify params, execute pre action hooks, perform the action,
    /// execute post action hooks and emit the RequestCompleted event, plus returning the result.
    /// It's up to the module to decode and encode params appropriately.
    /// @param ipOrg_ address of the IPOrg or zero address
    /// @param caller_ address requesting the execution
    /// @param moduleParams_ encoded params for module action
    /// @param preHookParams_ encoded params for pre action hooks
    /// @param postHookParams_ encoded params for post action hooks
    /// @return result of the module action
    function execute(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata moduleParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external returns (bytes memory result);

    /// @notice Configuration entrypoint.
    /// @dev It will verify params and configure the module.
    /// It's up to the module to decode and encode params appropriately.
    /// @param ipOrg_ address of the IPOrg or zero address
    /// @param caller_ address requesting the execution
    /// @param params_ encoded params for module configuration
    /// @return result of the module configuration
    function configure(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) external returns (bytes memory result);

}
