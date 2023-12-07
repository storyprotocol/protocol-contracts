// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;
import { ICallbackHandler } from "contracts/interfaces/hooks/base/ICallbackHandler.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title MockCallbackHandler
/// @notice This contract is a mock for testing the ICallbackHandler interface.
/// @dev It extends the ERC165 contract and implements the ICallbackHandler interface.
contract MockCallbackHandler is ERC165, ICallbackHandler {
    bytes32 public lastHandledRequestId;
    bytes public lastHandledCallbackData;

    /// @notice Handles a hook callback.
    /// @dev This function stores the input parameters for later inspection.
    /// @param requestId The ID of the request.
    /// @param callbackData The data for the callback.
    function handleHookCallback(bytes32 requestId, bytes calldata callbackData) external override {
        // Store the parameters for later inspection
        lastHandledRequestId = requestId;
        lastHandledCallbackData = callbackData;
    }

    /// @notice Checks if the contract supports an interface.
    /// @dev This function returns true if the interface ID is for the ICallbackHandler interface.
    /// @param interfaceId The ID of the interface.
    /// @return true if the contract supports the interface, false otherwise.
    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        // Check if the interface ID is for the ICallbackHandler interface
        return interfaceId == type(ICallbackHandler).interfaceId || super.supportsInterface(interfaceId);
    }
}
