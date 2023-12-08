// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title Callback Handler Interface
/// @notice This interface defines the method for handling hook callbacks.
/// @dev Modules that call AsyncHooks should implement this interface.
interface ICallbackHandler is IERC165 {
    /// @notice Handles a callback from an asynchronous call.
    /// @param requestId_ The id of the request.
    /// @param callbackData_ The data returned by the callback.
    function handleHookCallback(bytes32 requestId_, bytes calldata callbackData_) external;
}
