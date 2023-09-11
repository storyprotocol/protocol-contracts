// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

/// @notice Identifies the collect payment type configured for an IP asset.
/// TODO: Add ERC-721 and ERC-1155 as configurable payment types.
enum PaymentType {
    NATIVE, // Utilize the native token (e.g. ETH on Ethereum or OP on Optimism)
    ERC20   // Utilize an ERC-20 token
}

