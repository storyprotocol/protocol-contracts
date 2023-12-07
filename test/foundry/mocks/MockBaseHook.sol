// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;
import { BaseHook } from "contracts/hooks/base/BaseHook.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title MockBaseHook
/// @notice This contract is a mock for testing the BaseHook contract.
/// @dev It extends the BaseHook contract and implements its constructor.
contract MockBaseHook is BaseHook {

    /// @notice Constructs the MockBaseHook contract.
    /// @param accessControl_ The address of the access control contract.
    /// @dev The constructor sets the access control address.
    constructor(
        address accessControl_
    ) BaseHook(accessControl_) {}

    /// @notice Mock validation function for testing the hook configuration.
    /// @dev This function is used for testing purposes in the MockBaseHook contract.
    /// It simulates the validation of the hook configuration by reverting with an error if the configuration equals "ERROR".
    /// If the validation passes (i.e., the configuration does not equal "ERROR"), nothing happens.
    /// @param hookConfig_ The mock configuration data for the hook, encoded as bytes.
    function _validateConfig(bytes memory hookConfig_) internal pure override {
        if (keccak256(hookConfig_) == keccak256(abi.encode("ERROR"))) {
            revert Errors.ZeroAddress();
        }
    }
}
