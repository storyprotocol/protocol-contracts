// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title Collect Module Library
library Collect {

    ////////////////////////////////////////////////////////////////////////////
    //                              CollectModule                             //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Parameters passed to initialize a collect module for an IP asset.
    struct InitCollectParams {
        uint256 franchiseId; // The id of the franchise tied to the IP asset.
        uint256 ipAssetId; // The id of the IP asset under the franchise.
        address collectNftImpl; // The address of the collect NFT impl to use.
        bytes data; // Additional data to be used for initialization.
    }

    /// @notice Parameters passed for collect processing for an IP asset.
    struct CollectParams {
        uint256 franchiseId; // The id of the franchise tied to the IP asset.
        uint256 ipAssetId; // The id of the IP asset being collected.
        address collector; // The address designated for NFT collection.
        bytes collectData; // Additional data passed for module collection.
        bytes collectNftInitData; // Additional data passed for NFT initialization.
        bytes collectNftData; // Additional data passed for NFT collection.
    }

    /// @notice Collect module settings saved for a franchise IP asset.
    /// @dev A zero address `collectNftImpl` means to use a module default NFT impl.
    struct CollectInfo {
        bool initialized; // Whether the collect module was initialized.
        address collectNft; // The collect NFT that an IP asset is bound to.
        address collectNftImpl; // The collect NFT impl address being used.
    }

    /// @notice Identifies the collect payment type configured for an IP asset.
    /// TODO: Add ERC-721 and ERC-1155 as configurable payment types.
    enum PaymentType {
        NATIVE, // Utilize the native token (e.g. ETH on Ethereum or OP on Optimism)
        ERC20 // Utilize an ERC-20 token
    }

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

    ////////////////////////////////////////////////////////////////////////////
    //                                CollectNFT                              //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Parameters passed to initialize a collect NFT.
    struct InitCollectNFTParams {
        address ipAssetRegistry; // Address of the registry of the bound IP asset.
        uint256 ipAssetId; // The id of the IP asset bound to the collect NFT.
        bytes data; // Additional data used for NFT initialization.
    }

}
