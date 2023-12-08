// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { ModuleKey } from "contracts/lib/modules/Module.sol";

/// @title Story Protocol Module Interface.
/// @notice This interface must be implemented by all protocol modules in Story Protocol,
///         providing the base functionality needed for authorization and execution
///         logic centered around IP assets.
interface IModule {
    /// The execution of the module is pending, and will need to be executed again.
    event RequestPending(address indexed sender);
    /// Module execution completed successfully.
    event RequestCompleted(address indexed sender);
    /// Module execution failed.
    event RequestFailed(address indexed sender, string reason);

    /// @notice Gets the protocol-wide key associated with the module.
    /// @return The bytes32 identifier of the module.
    function moduleKey() external pure returns (ModuleKey);

    /// @notice Main execution entrypoint.
    /// @dev This function verifies encoded module params, executes any pre-action hooks,
    ///      performs the main module logic, and then executes any post-action hooks.
    ///      Modules must decide themselves how parameters are encoded and decoded.
    /// @param ipOrg_ Address of the IP Org or the zero address (for protocol-wide modules).
    /// @param caller_ Address of the caller.
    /// @param moduleParams_ Encoded params to be decoded for module execution.
    /// @param preHookParams_ Encoded params used for pre-hook execution logic.
    /// @param postHookParams_ Encoded params used for post-hook execution logic.
    /// @return result of the module action
    function execute(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata moduleParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external returns (bytes memory result);

    /// @notice Module configuration entrypoint.
    /// @dev Note that it is up to the module on how the parameters should be
    ///      encoded, unpacked, and used for configuration.
    /// @param ipOrg_ Address of the IP Org or the zero address (for protocol-wide modules).
    /// @param caller_ Address of configuration caller.
    /// @param params_ ABI-encoded parameters used for module configuration.
    /// @return result Result of the module configuration expressed as a bytes array.
    function configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) external returns (bytes memory result);
}
