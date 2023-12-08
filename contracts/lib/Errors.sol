// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

/// @title Errors Library
/// @notice Library for all Story Protocol contract errors.
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
    error BaseModule_ZeroLicenseRegistry();
    error BaseModule_OnlyModuleRegistry();

    /// @notice The caller is not authorized to perform this operation.
    error BaseModule_Unauthorized();

    ////////////////////////////////////////////////////////////////////////////
    //                            HookRegistry                                //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The hook is already registered.
    error HookRegistry_RegisteringDuplicatedHook();

    /// @notice This error is thrown when trying to register a hook with the address 0.
    error HookRegistry_RegisteringZeroAddressHook();

    /// @notice This error is thrown when the caller is not IP Org owner.
    error HookRegistry_CallerNotIPOrgOwner();

    /// @notice This error is thrown when trying to register more than the maximum allowed number of hooks.
    error HookRegistry_MaxHooksExceeded();

    /// @notice Hooks configuration array length does not match that of the hooks array.
    error HookRegistry_HooksConfigLengthMismatch();

    /// @notice This error is thrown when the provided index is out of bounds of the hooks array.
    error HookRegistry_IndexOutOfBounds(uint256 hooksIndex);

    /// @notice The module may not be the zero address.
    error HookRegistry_ZeroModuleRegistry();

    /// @notice The provided hook has not been whitelisted.
    error HookRegistry_RegisteringNonWhitelistedHook(address hookAddress);

    ////////////////////////////////////////////////////////////////////////////
    //                      BaseRelationshipProcessor                         //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Call may only be processed by the relationship module.
    error BaseRelationshipProcessor_OnlyRelationshipModule();

    ////////////////////////////////////////////////////////////////////////////
    //                           ModuleRegistry                               //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The selected module has yet to been registered.
    error ModuleRegistry_ModuleNotYetRegistered();

    /// @notice The module depenedency has not yet been registered for the gatway.
    error ModuleRegistry_DependencyNotYetRegistered();

    /// @notice The module depenedency was already registered for the gateway.
    error ModuleRegistry_DependencyAlreadyRegistered();

    /// @notice The caller is not the org owner.
    error ModuleRegistry_CallerNotOrgOwner();

    /// @notice Hook has yet to be registered.
    error ModuleRegistry_HookNotRegistered(string hookKey);

    /// @notice The selected module was already registered.
    error ModuleRegistry_ModuleAlreadyRegistered();

    /// @notice The key of the targeted module does not match the provided key.
    error ModuleRegistry_ModuleKeyMismatch();

    /// @notice The caller is not authorized to call the module dependency.
    error ModuleRegistry_Unauthorized();

    /// @notice The gateway is not valid for registration.
    error ModuleRegistry_InvalidGateway();

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
    //                         UintArrayMask                               //
    ////////////////////////////////////////////////////////////////////////////

    error UintArrayMask_EmptyArray();

    ////////////////////////////////////////////////////////////////////////////
    //                               IPOrg                                    //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice IP identifier is over bounds.
    error IPOrg_IdOverBounds();

    /// @notice Licensing is not configured.
    error IPOrg_LicensingNotConfigured();

    /// @notice IP Org wrapper id does not exist.
    error IPOrg_IdDoesNotExist();

    ////////////////////////////////////////////////////////////////////////////
    //                             IPOrgController                            //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The caller is not the owner of the IP Org Controller.
    error IPOrgController_InvalidOwner();

    /// @notice IP Org does not exist.
    error IPOrgController_IPOrgNonExistent();

    /// @notice The caller is not the authorized IP Org owner.
    error IPOrgController_InvalidIPOrgOwner();

    /// @notice The new owner for an IP Org may not be the zero address.
    error IPOrgController_InvalidNewIPOrgOwner();

    /// @notice The owner transfer has not yet been initialized.
    error IPOrgController_OwnerTransferUninitialized();

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
    //                       LicensingFrameworkRepo                           //
    ////////////////////////////////////////////////////////////////////////////
    error LicensingFrameworkRepo_FrameworkAlreadyAdded();
    error LicensingFrameworkRepo_DuplicateParamType();
    error LicensingFrameworkRepo_TooManyParams();

    ////////////////////////////////////////////////////////////////////////////
    //                        LicensingModule                                 //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The franchise does not exist.
    error LicensingModule_CallerNotIpOrgOwner();
    error LicensingModule_InvalidConfigType();
    error LicensingModule_InvalidTermCommercialStatus();
    error LicensingModule_IpOrgFrameworkAlreadySet();
    error LicensingModule_DuplicateTermId();
    error LicensingModule_CommercialLicenseNotAllowed();
    error LicensingModule_NonCommercialTermsRequired();
    error LicensingModule_IpOrgNotConfigured();
    error LicensingModule_IpOrgAlreadyConfigured();
    error LicensingModule_ipOrgTermNotFound();
    error LicensingModule_ShareAlikeDisabled();
    error LicensingModule_InvalidAction();
    error LicensingModule_CallerNotLicensor();
    error LicensingModule_ParentLicenseNotActive();
    error LicensingModule_DerivativeNotAllowed();
    error LicensingModule_InvalidIpa();
    error LicensingModule_CallerNotLicenseOwner();
    error LicensingModule_CantFindParentLicenseOrRelatedIpa();
    error LicensingModule_InvalidLicenseeType();
    error LicensingModule_InvalidLicensorType();
    error LicensingModule_InvalidLicensorConfig();
    error LicensingModule_InvalidParamValue();
    error LicensingModule_InvalidParamsLength();
    error LicensingModule_DuplicateParam();
    error LicensingModule_ReciprocalCannotSetParams();
    error LicensingModule_ParamSetByIpOrg();
    error LicensingModule_InvalidInputValue();
    error LicensingModule_IpOrgFrameworkNotSet();

    ////////////////////////////////////////////////////////////////////////////
    //                            LicenseRegistry                             //
    ////////////////////////////////////////////////////////////////////////////

    error LicenseRegistry_UnknownLicenseId();
    error LicenseRegistry_CallerNotLicensingModule();
    error LicenseRegistry_CallerNotRevoker();
    error LicenseRegistry_CallerNotLicensingModuleOrLicensee();
    error LicenseRegistry_CallerNotLicensor();
    error LicenseRegistry_LicenseNotPendingApproval();
    error LicenseRegistry_InvalidLicenseStatus();
    error LicenseRegistry_ParentLicenseNotActive();
    error LicenseRegistry_IPANotActive();
    error LicenseRegistry_LicenseNotActive();
    error LicenseRegistry_LicenseAlreadyLinkedToIpa();

    ////////////////////////////////////////////////////////////////////////////
    //                            RegistrationModule                          //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The caller is not authorized to perform registration.
    error RegistrationModule_CallerNotAuthorized();

    /// @notice The configured caller is invalid.
    error RegistrationModule_InvalidCaller();

    /// @notice The IP asset does not exist.
    error RegistrationModule_IPAssetNonExistent();

    /// @notice The registration module for the IP Org was not yet configured.
    error RegistrationModule_IPOrgNotConfigured();

    /// @notice The registration configuration action is not valid.
    error RegistrationModule_InvalidConfigOperation();

    /// @notice The registration execution action is not valid.
    error RegistrationModule_InvalidExecutionOperation();

    /// @notice IP asset type is not in the list of supported types for
    /// the IP Org.
    error RegistrationModule_InvalidIPAssetType();

    /// @notice IPAsset types provided are more than the maximum allowed.
    error RegistrationModule_TooManyAssetTypes();

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

    /// @notice Trying an unsupported config action
    error RelationshipModule_InvalidConfigOperation();

    /// @notice Unauthorized caller
    error RelationshipModule_CallerNotIpOrgOwner();

    /// @notice Value not on Relatable enum
    error RelationshipModule_InvalidRelatable();

    /// @notice Getting an invalid relationship type
    error RelationshipModule_RelTypeNotSet(string relType);

    /// @notice Relating invalid src addresss
    error RelationshipModule_InvalidSrcAddress();

    /// @notice Relating invalid dst addresss
    error RelationshipModule_InvalidDstAddress();

    /// @notice Relating unsupported src ipOrg asset type
    error RelationshipModule_InvalidSrcId();

    /// @notice Relating unsupported dst ipOrg asset type
    error RelationshipModule_InvalidDstId();

    /// @notice For IPORG_ENTRY - IPORG_ENTRY relationships,
    /// ipOrg address must be set
    error RelationshipModule_IpOrgRelatableCannotBeProtocolLevel();

    /// @notice Index is not found for the asset types of that IP Org.
    error RelationshipModule_UnsupportedIpOrgIndexType();

    ////////////////////////////////////////////////////////////////////////////
    //                                RoyaltyNFT                              //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Mismatch between parity of accounts and their respective allocations.
    error RoyaltyNFT_AccountsAndAllocationsMismatch(uint256 accountsLength, uint256 allocationsLength);

    /// @notice Invalid summation for royalty NFT allocations.
    error RoyaltyNFT_InvalidAllocationsSum(uint32 allocationsSum);

    ////////////////////////////////////////////////////////////////////////////
    //                                  Hook                                  //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice The hook request was not found.
    error Hook_RequestedNotFound();

    /// @notice The sync operation is not supported in Async hooks.
    error Hook_UnsupportedSyncOperation();

    /// @notice The async operation is not supported in Sync hooks.
    error Hook_UnsupportedAsyncOperation();

    /// @notice The callback function can only called by designated callback caller.
    error Hook_OnlyCallbackCallerCanCallback(address current, address expected);

    /// @notice Invalid async request ID.
    error Hook_InvalidAsyncRequestId(bytes32 invalidRequestId);

    /// @notice The address is not the owner of the token.
    error TokenGatedHook_NotTokenOwner(address tokenAddress, address ownerAddress);

    error Hook_AsyncHookError(bytes32 requestId, string reason);

    /// @notice Invalid Hook configuration.
    error Hook_InvalidHookConfig(string reason);

    ////////////////////////////////////////////////////////////////////////////
    //                       LicensorApprovalHook                             //
    ////////////////////////////////////////////////////////////////////////////

    error LicensorApprovalHook_ApprovalAlreadyRequested();
    error LicensorApprovalHook_InvalidLicensor();
    error LicensorApprovalHook_InvalidLicenseId();
    error LicensorApprovalHook_NoApprovalRequested();
    error LicensorApprovalHook_InvalidResponseStatus();
}
