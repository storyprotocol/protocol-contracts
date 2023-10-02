// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { PaymentType } from "./CollectPaymentModuleEnums.sol";

/// @notice Payment collect module settings saved for a franchise IP asset.
struct CollectPaymentInfo {
    address paymentToken; // The payment token address (if not native).
    PaymentType paymentType; // The type of payment being made.
    uint256 paymentAmount; // The required amount of the payment token.
    address payable paymentRecipient; // Payment receipient address.
}

/// @notice Parameters passed for collect payment processing for an IP asset.
/// TODO: Add a signature field to accept signature-relayed collects.
struct CollectPaymentParams {
    address paymentToken; // The payment token address (if not native).
    PaymentType paymentType; // The type of payment being made.
    uint256 paymentAmount; // The required amount of the payment token.
}
