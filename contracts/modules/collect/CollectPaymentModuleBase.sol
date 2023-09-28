// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICollectPaymentModule } from "contracts/interfaces/ICollectPaymentModule.sol";

import { CollectModuleBase } from "./CollectModuleBase.sol";
import { InitCollectParams, CollectParams } from "contracts/lib/CollectModuleStructs.sol";
import { CollectPaymentInfo, CollectPaymentParams } from "contracts/lib/CollectPaymentModuleStructs.sol";
import { PaymentType } from "contracts/lib/CollectPaymentModuleEnums.sol";

/// @title Collect Payment Module Base
/// @notice This is the Story Protocol base payment collect module, which allows
///         binding enrolled IP assets to NFTs that can be minted for a specific
///         fee according to franchise configured payment rules.
abstract contract CollectPaymentModuleBase is CollectModuleBase, ICollectPaymentModule {

    // ERC-1967 style storage slots used for collect payment module storage.
    struct CollectPaymentModuleStorage {

        // Maps IP assets (franchiseId, ipAssetId) to collect payment settings.
        mapping(uint256 => mapping(uint256 => CollectPaymentInfo)) paymentInfo;
    }

    // The ERC-1967 storage slot associated with the collect payment module:
    // keccak256("story-protocol.collect-paymnt-module.storage") - 1;
    bytes32 private constant _COLLECT_PAYMENT_MODULE_STORAGE = 0x5dfab49ded706b2f2f30c864b856c7ede3dea7f2e0652ef85d5676b6e4568675;

    /// @notice Instantiates a new collect payment module.
    /// @param franchiseRegistry The protocol-wide franchise registry address.
    /// @param defaultCollectNFTImpl The default collect NFT impl address.
    constructor(
        address franchiseRegistry,
        address defaultCollectNFTImpl
    ) CollectModuleBase(franchiseRegistry, defaultCollectNFTImpl) {}

    /// @notice Returns the collect payment info associated with an IP asset.
    /// @param  franchiseId The id of the franchise of the specified IP asset.
    /// @param  ipAssetId The id of the specified IP asset within the franchise.
    /// @return Payment info associated with the configured IP asset collect.
    function getPaymentInfo(uint256 franchiseId, uint256 ipAssetId) public view returns (CollectPaymentInfo memory) {
        CollectPaymentModuleStorage storage $ = _getCollectPaymentModuleStorage();
        return $.paymentInfo[franchiseId][ipAssetId];
    }

    /// @notice Initializes the collect payment module for a specific IP asset.
    /// @param initCollectParams Collect module init data, including IP asset
    ///        id, collect NFT impl address, and payment module init data.
    function initCollect(InitCollectParams calldata initCollectParams) public virtual override(CollectModuleBase, ICollectPaymentModule) {
        super.initCollect(initCollectParams);
    }

    /// @notice Performs a collect on a specific IP asset, processing the module
    ///         configured payment in the process.
    /// @param collectParams Collect module collect data, including IP asset id,
    ///         collector address, and collect payment module processing data.
    /// @return collectNFT The address of the collected NFT.
    /// @return collectNFTId The id of the collected collect NFT.
    /// TODO: Add payment reentrancy guard
    function collect(CollectParams calldata collectParams) public virtual payable override(CollectModuleBase, ICollectPaymentModule) returns (address collectNFT, uint256 collectNFTId) {
        return super.collect(collectParams);
    }

    /// @dev Perform initialization of the collect payment module.
    /// @param initCollectParams Collect module init data, which includes
    ///        unformatted data used for collect payment module initialization.
    function _initCollect(InitCollectParams calldata initCollectParams) internal virtual override(CollectModuleBase) {

        // Decode the payment initialization info.
        CollectPaymentInfo memory paymentInfo = abi.decode(initCollectParams.data, (CollectPaymentInfo));

        // Validate that the payment information is valid.
        _validatePaymentInfo(paymentInfo);

        CollectPaymentModuleStorage storage $ = _getCollectPaymentModuleStorage();
        $.paymentInfo[initCollectParams.franchiseId][initCollectParams.ipAssetId] = paymentInfo;
    }

    /// @dev Perform collect module payment processing.
    /// @param collectParams Collect module collect data, which includes
    ///        unformatted data used for collect payment module processing.
    function _collect(CollectParams calldata collectParams) internal virtual override(CollectModuleBase) {

        // Decode the payment processing info.
        CollectPaymentParams memory paymentParams = abi.decode(collectParams.collectData, (CollectPaymentParams));

        // Process the payment.
        _processPayment(collectParams.franchiseId, collectParams.ipAssetId, collectParams.collector, paymentParams);
    }

    /// @dev Processes the payment for a given IP asset collect action.
    /// @param franchiseId Id of the franchise of the IP asset being processed.
    /// @param ipAssetId Id of the IP asset being processed.
    /// @param collector Address of collector, who is responsible for payment.
    /// @param paymentParams Collect params configuring the IP asset payment.
    /// TODO: Allow delegation of payments to other addresses by the collector.
    function _processPayment(
        uint256 franchiseId,
        uint256 ipAssetId,
        address collector,
        CollectPaymentParams memory paymentParams
    ) internal virtual {

        // Get the current payment info settings for the IP asset.
        CollectPaymentModuleStorage storage $ = _getCollectPaymentModuleStorage();
        CollectPaymentInfo memory paymentInfo = $.paymentInfo[franchiseId][ipAssetId];

        // Validate the passed in payment parameters.
        // TODO: Optimize struct re-use to be more memory efficient.
        _validatePaymentProcessing(paymentInfo, paymentParams, collector);

        if (paymentInfo.paymentType == PaymentType.NATIVE) {
            _transferNativeTokens(
                paymentInfo.paymentRecipient, paymentInfo.paymentAmount);
        } else if (paymentInfo.paymentType == PaymentType.ERC20) {
            _transferERC20(
                paymentInfo.paymentToken,
                collector,
                paymentInfo.paymentRecipient,
                paymentInfo.paymentAmount
            );
        }
    }

    /// @dev Checks whether the collect payment info to be configured is valid.
    /// @param paymentInfo Settings for collect payment such as amount or token.
    function _validatePaymentInfo(CollectPaymentInfo memory paymentInfo) internal virtual {

        // Revert if a zero payment amount is specified.
        if (paymentInfo.paymentAmount == 0) {
            revert CollectPaymentModuleAmountInvalid();
        }

        PaymentType paymentType = paymentInfo.paymentType;
        if (paymentType == PaymentType.NATIVE) {
            if (paymentInfo.paymentToken != address(0)) {
                revert CollectPaymentModuleInvalidSettings();
            }
        } else if (paymentType == PaymentType.ERC20) {
            // Revert if the specified token is not a contract.
            if (paymentInfo.paymentToken.code.length == 0) {
                revert CollectPaymentModuleTokenInvalid();
            }
        }
        // TODO: Add support for ERC-721 and ERC-1155 payment validation.
    }

    /// @dev Checks whether payment processing parameters are valid.
    /// @param paymentInfo Currently configured info for the collect payment.
    /// @param paymentParams Parameters passed for collect payment processing.
    function _validatePaymentProcessing(CollectPaymentInfo memory paymentInfo, CollectPaymentParams memory paymentParams, address collector) internal virtual {

        uint256 paymentAmount = paymentInfo.paymentAmount;
        address paymentToken = paymentInfo.paymentToken;
        PaymentType paymentType = paymentInfo.paymentType;

        if (
            paymentParams.paymentType != paymentType     ||
            paymentParams.paymentToken != paymentToken ||
            paymentParams.paymentAmount < paymentAmount
        ) {
            revert CollectPaymentModulePaymentParamsInvalid();
        }

        if (paymentType == PaymentType.NATIVE) {
            if (msg.value < paymentAmount) {
                revert CollectPaymentModulePaymentInsufficient();
            }
        } else if (paymentType == PaymentType.ERC20) {
            if (msg.value != 0) {
                revert CollectPaymentModuleNativeTokenNotAllowed();
            }
            if (IERC20(paymentToken).balanceOf(collector) < paymentAmount) {
                revert CollectPaymentModulePaymentInsufficient();
            }
        }
        // TODO: Add support for ERC-721 and ERC-1155 payment processing.
    }

    /// @dev Gets the ERC-1967 configured collect payment module storage slot.
    function _getCollectPaymentModuleStorage() private pure returns (CollectPaymentModuleStorage storage $) {
        assembly {
            $.slot := _COLLECT_PAYMENT_MODULE_STORAGE
        }
    }

    /// @dev Transfers `amount` of the native token to address `to`. `msg.value`
    ///      is assumed to have been forwarded from the collector to the module.
    /// @param to Recipient address of the native tokens.
    /// @param amount The amount of native tokens to send to the recipient.
    /// TODO: Allow for native token transfers via relayers.
    function _transferNativeTokens(
        address payable to,
        uint256 amount
    ) internal {
        (bool ok, ) = to.call{ value: amount }("");

        // If the call was unsuccessful, revert.
        if (!ok) {
            revert CollectPaymentModuleNativeTransferFailed();
        }
    }

    /// @dev Transfers `amount` of ERC-20 token `token` from `from` to `to`.
    ///      NOTE: Approvals MUST be set on this contract for transfers to work.
    /// @param token Address of the ERC-20 token contract.
    /// @param from Address whose ERC-20 funds are being transferred from.
    /// @param to Recipient address of the ERC-20 transfer.
    /// @param amount The amount of the ERC-20 to transfer.
    /// TODO: Allow for ERC-2612 permit based transfers.
    function _transferERC20(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        // Perform an ERC-20 `transferFrom` call, collecting the returned data.
        (bool ok, bytes memory data) = token.call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                amount
            )
        );

        // If the call was unsuccessful, revert.
        if (!ok) {
            revert CollectPaymentModuleERC20TransferFailed();
        }

        // Perform additional checks if the returned data is not empty.
        if (data.length != 0) {

            // If there was returned data, revert on unsupported ABI encoding.
            if (data.length < 32) {
                revert CollectPaymentModuleERC20TransferInvalidABIEncoding();
            }

            // If the token responded with an unsuccessful return value, revert.
            if (!abi.decode(data, (bool))) {
                revert CollectPaymentModuleERC20TransferInvalidReturnValue();
            }
        }
    }

}
