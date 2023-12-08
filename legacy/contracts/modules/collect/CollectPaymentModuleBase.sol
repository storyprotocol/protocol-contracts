// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICollectPaymentModule } from "contracts/interfaces/modules/collect/ICollectPaymentModule.sol";

import { CollectModuleBase } from "./CollectModuleBase.sol";
import { Collect } from "contracts/lib/modules/Collect.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Collect Payment Module Base
/// @notice This is the Story Protocol base payment collect module, which allows
///         linking enrolled IP assets to NFTs that can be minted for a specific
///         fee according to registry configured payment rules.
/// TODO: Add IP Asset Collection wide collect payment module settings.
abstract contract CollectPaymentModuleBase is CollectModuleBase, ICollectPaymentModule {

    // ERC-1967 style storage slots used for collect payment module storage.
    struct CollectPaymentModuleStorage {

        // Maps IP assets (ipAssetId) to collect payment settings.
        mapping(uint256 => Collect.CollectPaymentInfo) paymentInfo;
    }

    // The ERC-1967 storage slot associated with the collect payment module:
    // keccak256("story-protocol.collect-paymnt-module.storage") - 1;
    bytes32 private constant _COLLECT_PAYMENT_MODULE_STORAGE = 0x5dfab49ded706b2f2f30c864b856c7ede3dea7f2e0652ef85d5676b6e4568675;

    /// @notice Instantiates a new collect payment module.
    /// @param registry_ The IP Asset registry address.
    /// @param defaultCollectNftImpl_ The default collect NFT impl address.
    constructor(
        address registry_,
        address defaultCollectNftImpl_
    ) CollectModuleBase(registry_, defaultCollectNftImpl_) {}

    /// @notice Initializes the collect payment module for a specific IP asset.
    /// @param initCollectParams_ Collect module init data, including IP asset
    ///        id, collect NFT impl address, and payment module init data.
    function initCollect(Collect.InitCollectParams calldata initCollectParams_) public virtual override(CollectModuleBase, ICollectPaymentModule) {
        super.initCollect(initCollectParams_);
    }

    /// @notice Performs a collect on a specific IP asset, processing the module
    ///         configured payment in the process.
    /// @param collectParams_ Collect module collect data, including IP asset id,
    ///         collector address, and collect payment module processing data.
    /// @return collectNft The address of the collected NFT.
    /// @return collectNftId The id of the collected collect NFT.
    /// TODO: Add payment reentrancy guard
    function collect(Collect.CollectParams calldata collectParams_) public virtual payable override(CollectModuleBase, ICollectPaymentModule) returns (address collectNft, uint256 collectNftId) {
        return super.collect(collectParams_);
    }

    /// @notice Returns the collect payment info associated with an IP asset.
    /// @param  ipAssetId_ The id of the specified IP asset within the registry.
    /// @return Payment info associated with the configured IP asset collect.
    function getPaymentInfo(uint256 ipAssetId_) public view returns (Collect.CollectPaymentInfo memory) {
        CollectPaymentModuleStorage storage $ = _getCollectPaymentModuleStorage();
        return $.paymentInfo[ipAssetId_];
    }

    /// @dev Perform initialization of the collect payment module.
    /// @param initCollectParams_ Collect module init data, which includes
    ///        unformatted data used for collect payment module initialization.
    function _initCollect(Collect.InitCollectParams calldata initCollectParams_) internal virtual override(CollectModuleBase) {

        // Decode the payment initialization info.
        Collect.CollectPaymentInfo memory paymentInfo = abi.decode(initCollectParams_.data, (Collect.CollectPaymentInfo));

        // Validate that the payment information is valid.
        _validatePaymentInfo(paymentInfo);

        CollectPaymentModuleStorage storage $ = _getCollectPaymentModuleStorage();
        $.paymentInfo[initCollectParams_.ipAssetId] = paymentInfo;
    }

    /// @dev Perform collect module payment processing.
    /// @param collectParams_ Collect module collect data, which includes
    ///        unformatted data used for collect payment module processing.
    function _collect(Collect.CollectParams calldata collectParams_) internal virtual override(CollectModuleBase) {

        // Decode the payment processing info.
        Collect.CollectPaymentParams memory paymentParams = abi.decode(collectParams_.collectData, (Collect.CollectPaymentParams));

        // Process the payment.
        _processPayment(collectParams_.ipAssetId, collectParams_.collector, paymentParams);
    }

    /// @dev Processes the payment for a given IP asset collect action.
    /// @param ipAssetId_ Id of the IP asset being processed.
    /// @param collector_ Address of collector, who is responsible for payment.
    /// @param paymentParams_ Collect params configuring the IP asset payment.
    /// TODO: Allow delegation of payments to other addresses by the collector.
    function _processPayment(
        uint256 ipAssetId_,
        address collector_,
        Collect.CollectPaymentParams memory paymentParams_
    ) internal virtual {

        // Get the current payment info settings for the IP asset.
        CollectPaymentModuleStorage storage $ = _getCollectPaymentModuleStorage();
        Collect.CollectPaymentInfo memory paymentInfo = $.paymentInfo[ipAssetId_];

        // Validate the passed in payment parameters.
        // TODO: Optimize struct re-use to be more memory efficient.
        _validatePaymentProcessing(paymentInfo, paymentParams_, collector_);

        if (paymentInfo.paymentType == Collect.PaymentType.NATIVE) {
            _transferNativeTokens(
                paymentInfo.paymentRecipient, paymentInfo.paymentAmount);
        } else if (paymentInfo.paymentType == Collect.PaymentType.ERC20) {
            _transferERC20(
                paymentInfo.paymentToken,
                collector_,
                paymentInfo.paymentRecipient,
                paymentInfo.paymentAmount
            );
        }
    }

    /// @dev Checks whether the collect payment info to be configured is valid.
    /// @param paymentInfo_ Settings for collect payment such as amount or token.
    function _validatePaymentInfo(Collect.CollectPaymentInfo memory paymentInfo_) internal virtual {

        // Revert if a zero payment amount is specified.
        if (paymentInfo_.paymentAmount == 0) {
            revert Errors.CollectPaymentModule_AmountInvalid();
        }

        Collect.PaymentType paymentType = paymentInfo_.paymentType;
        if (paymentType == Collect.PaymentType.NATIVE) {
            if (paymentInfo_.paymentToken != address(0)) {
                revert Errors.CollectPaymentModule_InvalidSettings();
            }
        } else if (paymentType == Collect.PaymentType.ERC20) {
            // Revert if the specified token is not a contract.
            if (paymentInfo_.paymentToken.code.length == 0) {
                revert Errors.CollectPaymentModule_TokenInvalid();
            }
        }
        // TODO: Add support for ERC-721 and ERC-1155 payment validation.
    }

    /// @dev Checks whether payment processing parameters are valid.
    /// @param paymentInfo_ Currently configured info for the collect payment.
    /// @param paymentParams_ Parameters passed for collect payment processing.
    function _validatePaymentProcessing(Collect.CollectPaymentInfo memory paymentInfo_, Collect.CollectPaymentParams memory paymentParams_, address collector_) internal virtual {

        uint256 paymentAmount = paymentInfo_.paymentAmount;
        address paymentToken = paymentInfo_.paymentToken;
        Collect.PaymentType paymentType = paymentInfo_.paymentType;

        if (
            paymentParams_.paymentType != paymentType     ||
            paymentParams_.paymentToken != paymentToken ||
            paymentParams_.paymentAmount < paymentAmount
        ) {
            revert Errors.CollectPaymentModule_PaymentParamsInvalid();
        }

        if (paymentType == Collect.PaymentType.NATIVE) {
            if (msg.value < paymentAmount) {
                revert Errors.CollectPaymentModule_PaymentInsufficient();
            }
        } else if (paymentType == Collect.PaymentType.ERC20) {
            if (msg.value != 0) {
                revert Errors.CollectPaymentModule_NativeTokenNotAllowed();
            }
            if (IERC20(paymentToken).balanceOf(collector_) < paymentAmount) {
                revert Errors.CollectPaymentModule_PaymentInsufficient();
            }
        }
        // TODO: Add support for ERC-721 and ERC-1155 payment processing.
    }

    /// @dev Transfers `amount` of the native token to address `to`. `msg.value`
    ///      is assumed to have been forwarded from the collector to the module.
    /// @param to_ Recipient address of the native tokens.
    /// @param amount_ The amount of native tokens to send to the recipient.
    /// TODO: Allow for native token transfers via relayers.
    function _transferNativeTokens(
        address payable to_,
        uint256 amount_
    ) internal {
        (bool ok, ) = to_.call{ value: amount_ }("");

        // If the call was unsuccessful, revert.
        if (!ok) {
            revert Errors.CollectPaymentModule_NativeTransferFailed();
        }
    }

    /// @dev Transfers `amount` of ERC-20 token `token` from `from` to `to`.
    ///      NOTE: Approvals MUST be set on this contract for transfers to work.
    /// @param token_ Address of the ERC-20 token contract.
    /// @param from_ Address whose ERC-20 funds are being transferred from.
    /// @param to_ Recipient address of the ERC-20 transfer.
    /// @param amount_ The amount of the ERC-20 to transfer.
    /// TODO: Allow for ERC-2612 permit based transfers.
    function _transferERC20(
        address token_,
        address from_,
        address to_,
        uint256 amount_
    ) internal {
        // Perform an ERC-20 `transferFrom` call, collecting the returned data.
        (bool ok, bytes memory data) = token_.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from_,
                to_,
                amount_
            )
        );

        // If the call was unsuccessful, revert.
        if (!ok) {
            revert Errors.CollectPaymentModule_ERC20TransferFailed();
        }

        // Perform additional checks if the returned data is not empty.
        if (data.length != 0) {

            // If there was returned data, revert on unsupported ABI encoding.
            if (data.length < 32) {
                revert Errors.CollectPaymentModule_ERC20TransferInvalidABIEncoding();
            }

            // If the token responded with an unsuccessful return value, revert.
            if (!abi.decode(data, (bool))) {
                revert Errors.CollectPaymentModule_ERC20TransferInvalidReturnValue();
            }
        }
    }

    /// @dev Gets the ERC-1967 configured collect payment module storage slot.
    function _getCollectPaymentModuleStorage() private pure returns (CollectPaymentModuleStorage storage $) {
        assembly {
            $.slot := _COLLECT_PAYMENT_MODULE_STORAGE
        }
    }
}
