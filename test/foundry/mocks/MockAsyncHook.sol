// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { AsyncBaseHook } from "contracts/hooks/base/AsyncBaseHook.sol";

/// @title MockAsyncHook
/// @notice This contract is a mock for testing the AsyncBaseHook contract.
/// @dev It overrides the _requestAsyncCall and handleCallback functions for testing purposes.
contract MockAsyncHook is AsyncBaseHook {
    address immutable CALLBACK_CALLER;

    /// @notice Constructs the MockAsyncHook contract.
    /// @param accessControl_ The address of the access control contract.
    /// @param callbackCaller_ The address of the callback caller contract.
    /// @dev The constructor sets the access control and callback caller addresses.
    constructor(
        address accessControl_,
        address callbackCaller_
    ) AsyncBaseHook(accessControl_) {
        CALLBACK_CALLER = callbackCaller_;
    }

    /// @notice Requests an asynchronous call.
    /// @dev This function is overridden for testing purposes.
    /// It simply returns the input parameters.
    /// @param hookConfig_ The configuration of the hook.
    /// @param hookParams_ The parameters for the hook.
    /// @return hookData The data for the hook.
    /// @return requestId The ID of the request.
    function _requestAsyncCall(
        bytes memory hookConfig_,
        bytes memory hookParams_
    )
        internal
        virtual
        override
        returns (bytes memory hookData, bytes32 requestId)
    {
        // Simply return the input parameters
        return (
            abi.encode(hookConfig_, hookParams_),
            getRequestId(hookParams_)
        );
    }

    /// @notice Handles a callback.
    /// @dev This function is overridden for testing purposes.
    /// It simply calls the _handleCallback function with the input parameters.
    /// @param requestId_ The ID of the request.
    /// @param callbackData_ The data for the callback.
    function handleCallback(
        bytes32 requestId_,
        bytes calldata callbackData_
    ) external {
        _handleCallback(requestId_, getProcessedCallbackData(callbackData_));
    }

    function getRequestId(
        bytes memory hookParams_
    ) public pure returns (bytes32) {
        return bytes32(uint256(keccak256(hookParams_)));
    }

    function getProcessedCallbackData(bytes calldata callbackData_) public pure returns (bytes memory result) {
        string memory callbackData = abi.decode(callbackData_, (string));
        if (keccak256(abi.encodePacked("PASS")) == keccak256(abi.encodePacked(callbackData))) {
            result = abi.encode(true, callbackData);
        } else {
            result = abi.encode(false, callbackData);
        }
    }

    function _validateConfig(bytes memory) internal view override {}

    function _callbackCaller(
        bytes32
    ) internal view virtual override returns (address) {
        return CALLBACK_CALLER;
    }
}
