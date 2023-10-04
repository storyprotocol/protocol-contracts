// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { ICollectModuleEventsAndErrors } from "contracts/interfaces/modules/collect/ICollectModuleEventsAndErrors.sol";

/// @title Collect Payment Module Events & Errors Interface
interface ICollectPaymentModuleEventsAndErrors is
    ICollectModuleEventsAndErrors
{
    /// @notice The configured collect module payment amount is invalid.
    error CollectPaymentModuleAmountInvalid();

    /// @notice The ERC-20 transfer failed when processing the payment collect.
    error CollectPaymentModuleERC20TransferFailed();

    /// @notice The collect ERC-20 transfer was not properly ABI-encoded.
    error CollectPaymentModuleERC20TransferInvalidABIEncoding();

    /// @notice The collect ERC-20 transfer returned a non-successful value.
    error CollectPaymentModuleERC20TransferInvalidReturnValue();

    /// @notice Invalid settings were configured for the collect payment module.
    error CollectPaymentModuleInvalidSettings();

    /// @notice Native tokens are not allowed for the configured payment module.
    error CollectPaymentModuleNativeTokenNotAllowed();

    /// @notice Native tokens failed to transfer for the payment collect.
    error CollectPaymentModuleNativeTransferFailed();

    /// @notice Invalid parameters were passed in to the payment collect.
    error CollectPaymentModulePaymentParamsInvalid();

    /// @notice Insufficient funds were provided for the payment collect.
    error CollectPaymentModulePaymentInsufficient();

    /// @notice The token provided for the payment collect is invalid.
    error CollectPaymentModuleTokenInvalid();
}
