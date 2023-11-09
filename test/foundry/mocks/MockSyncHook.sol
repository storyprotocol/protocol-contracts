// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import { SyncBaseHook } from "contracts/hooks/base/SyncBaseHook.sol";

/// @title MockSyncHook
/// @notice This contract is a mock for testing the SyncBaseHook contract.
/// @dev It extends the SyncBaseHook contract and overrides its _executeSyncCall function.
contract MockSyncHook is SyncBaseHook {
    /// @notice Constructs the MockSyncHook contract.
    /// @param accessControl_ The address of the access control contract.
    /// @dev The constructor sets the access control address.
    constructor(
        address accessControl_
    ) SyncBaseHook(accessControl_) {}

    /// @notice Executes a synchronous call.
    /// @dev This function is overridden for testing purposes.
    /// It simply returns the input parameters.
    /// @param hookConfig_ The configuration of the hook.
    /// @param hookParams_ The parameters for the hook.
    /// @return The parameters for the hook.
    function _executeSyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    )
        internal
        virtual
        override
        returns (bytes memory)
    {
        // Simply return the input parameters
        return abi.encode(hookConfig_, hookParams_);
    }

    function _validateConfig(bytes memory) internal view override {}
}
