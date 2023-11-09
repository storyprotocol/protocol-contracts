// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title ICallbackHandler
/// @notice This interface defines the method for handling hook callbacks.
/// @dev Modules that call the AsyncHook usually implement this interface.
interface ICallbackHandler is IERC165 {
    /// @notice Handles a callback from an asynchronous call.
    /// @param requestId_ The ID of the request.
    /// @param callbackData_ The data returned by the callback.
    function handleHookCallback(bytes32 requestId_, bytes calldata callbackData_) external;
}
