// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IPAsset } from "contracts/lib/IPAsset.sol";

/// @title Errors
/// @notice Library for all contract errors, including a set of global errors.
library Errors {
    ////////////////////////////////////////////////////////////////////////////
    //                                  Globals                               //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The provided array may not be empty.
    error EmptyArray();

    /// @notice The arrays may not have a mismatch in length.
    error LengthMismatch();

    /// @notice The provided role does not exist for the given account.
    error MissingRole(bytes32 role, address account);

    /// @notice The provided identifier does not exist.
    error NonExistentID(uint256 id);

    /// @notice The caller is not authorized to perform the call.
    error Unauthorized();

    /// @notice The provided interface is not supported.
    error UnsupportedInterface(string name);

    /// @notice The zero address may not be used as input.
    error ZeroAddress();

    /// @notice The amount specified may not be zero.
    error ZeroAmount();

    ////////////////////////////////////////////////////////////////////////////
    //                            BaseModule                                  //
    ////////////////////////////////////////////////////////////////////////////

    error BaseModule_HooksParamsLengthMismatch(uint8 hookType);
    error BaseModule_ZeroIpaRegistry();
    error BaseModule_ZeroModuleRegistry();
    error BaseModule_ZeroLicenseRegistry();

    ////////////////////////////////////////////////////////////////////////////
    //                            HookRegistry                                //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The hook is already registered.
    error HookRegistry_RegisteringDuplicatedHook();
    error HookRegistry_RegisteringZeroAddressHook();
    error HookRegistry_CallerNotAdmin();
    error HookRegistry_MaxHooksExceeded();

    ////////////////////////////////////////////////////////////////////////////
    //                            BaseRelationshipProcessor                   //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Call may only be processed by the relationship module.
    error BaseRelationshipProcessor_OnlyRelationshipModule();

    ////////////////////////////////////////////////////////////////////////////
    //                           ModuleRegistry                               //
    ////////////////////////////////////////////////////////////////////////////

    error ModuleRegistry_ModuleNotRegistered(string moduleName);
    error ModuleRegistry_CallerNotOrgOwner();

    ////////////////////////////////////////////////////////////////////////////
    //                                 CollectModule                          //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Collect module caller is unauthorized.
    error CollectModule_CallerUnauthorized();

    /// @notice Collect NFT has already been initialized.
    error CollectModule_CollectNotYetInitialized();

    /// @notice Collect action is not authorized for the collect module.
    error CollectModule_CollectUnauthorized();

    /// @notice Collect module IP asset is already initialized.
    error CollectModule_IPAssetAlreadyInitialized();

    /// @notice Collect module IP asset does not exist.
    error CollectModule_IPAssetNonExistent();

    /// @notice Collect module provided IP asset registry does not exist.
    error CollectModule_IPOrgNonExistent();

    ////////////////////////////////////////////////////////////////////////////
    //                           CollectPaymentModule                         //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The configured collect module payment amount is invalid.
    error CollectPaymentModule_AmountInvalid();

    /// @notice The ERC-20 transfer failed when processing the payment collect.
    error CollectPaymentModule_ERC20TransferFailed();

    /// @notice The collect ERC-20 transfer was not properly ABI-encoded.
    error CollectPaymentModule_ERC20TransferInvalidABIEncoding();

    /// @notice The collect ERC-20 transfer returned a non-successful value.
    error CollectPaymentModule_ERC20TransferInvalidReturnValue();

    /// @notice Invalid settings were configured for the collect payment module.
    error CollectPaymentModule_InvalidSettings();

    /// @notice Native tokens are not allowed for the configured payment module.
    error CollectPaymentModule_NativeTokenNotAllowed();

    /// @notice Native tokens failed to transfer for the payment collect.
    error CollectPaymentModule_NativeTransferFailed();

    /// @notice Invalid parameters were passed in to the payment collect.
    error CollectPaymentModule_PaymentParamsInvalid();

    /// @notice Insufficient funds were provided for the payment collect.
    error CollectPaymentModule_PaymentInsufficient();

    /// @notice The token provided for the payment collect is invalid.
    error CollectPaymentModule_TokenInvalid();

    ////////////////////////////////////////////////////////////////////////////
    //                                  CollectNFT                            //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Collect NFT has already been initialized.
    error CollectNFT_AlreadyInitialized();

    /// @notice Caller of the Collect NFT is not authorized.
    error CollectNFT_CallerUnauthorized();

    /// @notice Collector address is not valid.
    error CollectNFT_CollectorInvalid();

    /// @notice IP asset bound to the Collect NFT does not exist.
    error CollectNFT_IPAssetNonExistent();

    ////////////////////////////////////////////////////////////////////////////
    //                                   ERC721                               //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Originating address does not own the NFT.
    error ERC721_OwnerInvalid();

    /// @notice Receiving address cannot be the zero address.
    error ERC721_ReceiverInvalid();

    /// @notice Receiving contract does not implement the ERC-721 wallet interface.
    error ERC721_SafeTransferUnsupported();

    /// @notice Sender is not NFT owner, approved address, or owner operator.
    error ERC721_SenderUnauthorized();

    /// @notice Token has already been minted.
    error ERC721_TokenAlreadyMinted();

    /// @notice NFT does not exist.
    error ERC721_TokenNonExistent();

    ////////////////////////////////////////////////////////////////////////////
    //                                 IPAccountImpl                          //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice IP account caller is not the owner.
    error IPAccountImpl_CallerNotOwner();

    ////////////////////////////////////////////////////////////////////////////
    //                               IPAccountRegistry                        //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice IP account implementation does not exist.
    error IPAccountRegistry_NonExistentIpAccountImpl();

    /// @notice IP account initialization failed.
    error IPAccountRegistry_InitializationFailed();

    ////////////////////////////////////////////////////////////////////////////
    //                         LibUintArrayMask                               //
    ////////////////////////////////////////////////////////////////////////////

    error LibUintArrayMask_EmptyArray();
    error LibUintArrayMask_UndefinedArrayElement();
    /// @notice IP asset is invalid.
    error LibUintArrayMask_InvalidType(IPAsset.IPAssetType ipAsset);

    ////////////////////////////////////////////////////////////////////////////
    //                              IPOrg                           //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice IP identifier is over bounds.
    error IPOrg_IdOverBounds();

    /// @notice Licensing is not configured.
    error IPOrg_LicensingNotConfigured();

    ////////////////////////////////////////////////////////////////////////////
    //                                LibDuration                             //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The caller is not the designated renwer.
    error LibDuration_CallerNotRenewer();

    /// @notice The start time is not valid.
    error LibDuration_InvalidStartTime();

    /// @notice The proposed license is not renewable.
    error LibDuration_NotRenewable();

    /// @notice A zero TTL may not be used for configuration.
    error LibDuration_ZeroTTL();
    
    ////////////////////////////////////////////////////////////////////////////
    //                             LicensingModule                            //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The franchise does not exist.
    error LicensingModule_NonExistentIPOrg();

    /// @notice The root license is not active
    error LicensingModule_RootLicenseNotActive(uint256 rootLicenseId);

    /// @notice The revoker may not be a zero address.
    error LicensingModule_ZeroRevokerAddress();

    ////////////////////////////////////////////////////////////////////////////
    //                              RightsManager                             //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Root license is already configured.
    error RightsManager_AlreadyHasRootLicense();

    /// @notice License cannot be sublicensed.
    error RightsManager_CannotSublicense();

    /// @notice Commercial terms do not match.
    error RightsManager_CommercialTermsMismatch();

    /// @notice License is inactive.
    error RightsManager_InactiveLicense();

    /// @notice Parent license is inactive.
    error RightsManager_InactiveParentLicense();

    /// @notice The license registry is not configured.
    error RightsManager_LicenseRegistryNotConfigured();

    /// @notice NFT is not associated with a license.
    error RightsManager_NFTHasNoAssociatedLicense();

    /// @notice Caller is not owner of parent license.
    error RightsManager_NotOwnerOfParentLicense();

    /// @notice The targeted license is not a sublicense.
    error RightsManager_NotSublicense();

    /// @notice Sender is not the license revoker.
    error RightsManager_SenderNotRevoker();

    /// @notice A create franchise root license must be used.
    error RightsManager_UseCreateIPOrgRootLicenseInstead();

    /// @notice The revoker may not be the zero address.
    error RightsManager_ZeroRevokerAddress();

    ////////////////////////////////////////////////////////////////////////////
    //                             MultiTermsProcessor                        //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Too many terms were selected.
    error MultiTermsProcessor_TooManyTermsProcessors();

    ////////////////////////////////////////////////////////////////////////////
    //                            RelationshipRegistry                        //
    ////////////////////////////////////////////////////////////////////////////

    error RelationshipRegistry_ModuleRegistryZeroAddress();
    error RelationshipRegistry_RelationshipHaveZeroAddress();
    error RelationshipRegistry_RelatingSameAsset();
    error RelationshipRegistry_UnsupportedRelatedElements();
    error RelationshipRegistry_CallerNotModuleRegistry();
    error RelationshipRegistry_RelationshipAlreadyExists();
    error RelationshipRegistry_RelationshipDoesNotExist();
    error RelationshipRegistry_UndefinedElements();

    ////////////////////////////////////////////////////////////////////////////
    //                            RelationshipModule                          //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Unable to relate to another franchise.
    error RelationshipModule_CannotRelateToOtherIPOrg();

    /// @notice The intent has already been registered.
    error RelationshipModule_IntentAlreadyRegistered();

    /// @notice The selected TTL is not valid.
    error RelationshipModule_InvalidTTL();

    /// @notice The selected end timestamp is not valid.
    error RelationshipModule_InvalidEndTimestamp();

    /// @notice Relationship does not exist.
    error RelationshipModule_NonExistingRelationship();

    /// @notice The relationship source IP type is not supported.
    error RelationshipModule_UnsupportedRelationshipSrc();

    /// @notice The relationship destination IP type is not supported.
    error RelationshipModule_UnsupportedRelationshipDst();

    ////////////////////////////////////////////////////////////////////////////
    //                                RoyaltyNFT                              //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Mismatch between parity of accounts and their respective allocations.
    error RoyaltyNFT_AccountsAndAllocationsMismatch(
        uint256 accountsLength,
        uint256 allocationsLength
    );

    /// @notice Invalid summation for royalty NFT allocations.
    error RoyaltyNFT_InvalidAllocationsSum(uint32 allocationsSum);
}
