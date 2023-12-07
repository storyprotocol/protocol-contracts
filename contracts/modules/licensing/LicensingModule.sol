// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { LicensingFrameworkRepo } from "./LicensingFrameworkRepo.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { PIPLicensingTerms } from "contracts/lib/modules/PIPLicensingTerms.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";

/// @title Licensing module
/// @notice Story Protocol module that:
/// - Enables each IP Org to select a licensing framework fron LicensingFrameworkRepo
/// - Enables Other modules to mint License NFTs, and attach them to IPAs
/// - Enables license holders to create derivative licenses and sublicenses
/// Thanks to the authors of ERC-5218 for the inspiration (see https://eips.ethereum.org/EIPS/eip-5218)
contract LicensingModule is BaseModule {
    using ShortStrings for *;
    using FixedSet for FixedSet.ShortStringSet;

    event IpOrgLicensingFrameworkSet(
        address indexed ipOrg,
        string frameworkId,
        string url,
        Licensing.LicensorConfig licensorConfig
    );

    event ParameterSet(
        address indexed ipOrg,
        string paramTag,
        bytes defaultValue
    );

    /// @notice Holds the supported paramerter tags for each ipOrg, and the default values
    /// ipOrg -> paramTag -> bytes
    // TODO(ramarti): optimize for only 1 sload
    mapping(address => mapping(ShortString => bytes)) private _ipOrgParamValues;
    mapping(address => Licensing.LicensorConfig) private _licensorConfig;
    mapping(address => string) private _ipOrgFrameworkIds;

    LicensingFrameworkRepo public immutable LICENSING_FRAMEWORK_REPO;
    address public immutable DEFAULT_REVOKER;

    constructor(
        ModuleConstruction memory params_,
        address licFrameworkRepo_,
        address defaultRevoker_
    ) BaseModule(params_) {
        if (licFrameworkRepo_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        LICENSING_FRAMEWORK_REPO = LicensingFrameworkRepo(licFrameworkRepo_);
        if (defaultRevoker_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        DEFAULT_REVOKER = defaultRevoker_;
    }

    function getIpOrgLicensorConfig(
        address ipOrg_
    ) external view returns (Licensing.LicensorConfig) {
        return _licensorConfig[ipOrg_];
    }

    function getDefaultValueForParam(
        address ipOrg_,
        string calldata paramTag_
    ) external view returns (bytes memory) {
        return _ipOrgParamValues[ipOrg_][paramTag_.toShortString()];
    }

    ////////////////////////////////////////////////////////////////////////////
    //                          Create License                                //
    ////////////////////////////////////////////////////////////////////////////

    /// Module entrypoing to verify execution call
    function _verifyExecution(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) internal virtual override {
        // Verification done in _performAction for efficiency
    }

    /// Module entrypoint to create licenses
    function _performAction(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) internal virtual override returns (bytes memory result) {
        (bytes32 action, bytes memory actionParams) = abi.decode(
            params_,
            (bytes32, bytes)
        );
        if (action == Licensing.CREATE_LICENSE) {
            // Mint new license
            return _createLicense(ipOrg_, caller_, actionParams);
        } else if (action == Licensing.ACTIVATE_LICENSE) {
            // Activate license pending licensor approval
            uint256 licenseId = abi.decode(actionParams, (uint256));
            LICENSE_REGISTRY.activateLicense(licenseId, caller_);
            return bytes("");
        } else if (action == Licensing.LINK_LNFT_TO_IPA) {
            // Link derivative license to derivative IPA
            (uint256 licenseId, uint256 ipaId) = abi.decode(
                actionParams,
                (uint256, uint256)
            );
            LICENSE_REGISTRY.linkLnftToIpa(licenseId, ipaId);
            return bytes("");
        } else {
            revert Errors.LicensingModule_InvalidAction();
        }
    }

    function _createLicense(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) private returns (bytes memory result) {
        Licensing.LicenseCreation memory input = abi.decode(
            params_,
            (Licensing.LicenseCreation)
        );

        address licensor = _getLicensor(
            address(ipOrg_),
            caller_,
            input.parentLicenseId,
            input.ipaId
        );
        // ------ Derivative license checks ------
        if (input.parentLicenseId != 0) {
            if (!LICENSE_REGISTRY.isLicenseActive(input.parentLicenseId)) {
                revert Errors.LicensingModule_ParentLicenseNotActive();
            }
        }
        // If this is a derivative and parent is reciprocal, license parameters
        // cannot be changed in the new license
        if (
            input.parentLicenseId != 0 &&
            LICENSE_REGISTRY.isReciprocal(input.parentLicenseId)
        ) {
            if (input.params.length > 0) {
                revert Errors.LicensingModule_ReciprocalCannotSetParams();
            }
            return
                abi.encode(
                    LICENSE_REGISTRY.addReciprocalLicense(
                        input.parentLicenseId,
                        licensor,
                        caller_,
                        input.ipaId
                    )
                );
        } else {
            // If this is not a derivative, or parent is not reciprocal, caller must be
            // the licensor
            if (licensor != caller_) {
                revert Errors.LicensingModule_CallerNotLicensor();
            }
            // Parameters can be changed if IpOrg has not set them
            return
                abi.encode(
                    _addNonReciprocalLicense(
                        address(ipOrg_),
                        caller_,
                        licensor,
                        input,
                        _ipOrgFrameworkIds[address(ipOrg_)]
                    )
                );
        }
    }

    function _addNonReciprocalLicense(
        address ipOrg_,
        address caller_,
        address licensor_,
        Licensing.LicenseCreation memory input,
        string memory frameworkId_
    ) private returns (uint256) {
        uint256 inputLength = input.params.length;
        // Get all param tags from framework
        Licensing.ParamDefinition[]
            memory supportedParams = LICENSING_FRAMEWORK_REPO.getParameterDefs(
                frameworkId_
            );
        uint256 supportedLength = supportedParams.length;

        Licensing.ParamValue[]
            memory licenseParams = new Licensing.ParamValue[](supportedLength);
        bool isReciprocal;
        bool derivativeNeedsApproval;
        mapping(ShortString => bytes)
            storage _defaultValues = _ipOrgParamValues[ipOrg_];

        // First, get ipOrg defaults
        for (uint256 i = 0; i < supportedLength; i++) {
            // For every supported parameter
            Licensing.ParamDefinition memory paramDef = supportedParams[i];
            // Get the default value set by ipOrg
            bytes memory defaultValue = _defaultValues[paramDef.tag];
            // Find if user has provided a value for this param
            bytes memory inputValue;
            for (uint256 j = 0; j < inputLength; j++) {
                Licensing.ParamValue memory inputParam = input.params[j];
                if (ShortStringOps._equal(inputParam.tag, paramDef.tag)) {
                    inputValue = inputParam.value;
                    break;
                }
            }
            // Decide which value to use
            bytes memory resultValue = _decideUserOrDefault(
                inputValue,
                defaultValue,
                paramDef.paramType
            );

            // Set value in license params
            licenseParams[i] = Licensing.ParamValue(paramDef.tag, resultValue);
            if (keccak256(resultValue) == keccak256("")) {
                continue;
            }
            // If param is not empty, check for Derivative license flags
            if (
                ShortStringOps._equal(
                    paramDef.tag,
                    PIPLicensingTerms.DERIVATIVES_WITH_RECIPROCAL_LICENSE
                )
            ) {
                isReciprocal = abi.decode(resultValue, (bool));
            } else if (
                ShortStringOps._equal(
                    paramDef.tag,
                    PIPLicensingTerms.DERIVATIVES_WITH_APPROVAL
                )
            ) {
                derivativeNeedsApproval = abi.decode(resultValue, (bool));
            }
        }
        // Create license
        Licensing.LicenseData memory newLicense = Licensing.LicenseData({
            status: Licensing.LicenseStatus.Active,
            isReciprocal: isReciprocal,
            derivativeNeedsApproval: derivativeNeedsApproval,
            revoker: DEFAULT_REVOKER,
            licensor: licensor_,
            ipOrg: ipOrg_,
            frameworkId: frameworkId_.toShortString(),
            ipaId: input.ipaId,
            parentLicenseId: input.parentLicenseId
        });
        return LICENSE_REGISTRY.addLicense(newLicense, caller_, licenseParams);
    }

    function _decideUserOrDefault(
        bytes memory inputValue,
        bytes memory defaultValue,
        Licensing.ParameterType paramType
    ) private pure returns (bytes memory) {
        if (inputValue.length > 0) {
            // If user has set it, but ipOrg has too, revert
            if (defaultValue.length > 0) {
                revert Errors.LicensingModule_ParamSetByIpOrg();
            }
            // If user has set it and ipOrg has not, user value selected
            if (!Licensing._validateParamValue(paramType, inputValue)) {
                // hoping to catch some bad encoding
                revert Errors.LicensingModule_InvalidInputValue();
            }
            return inputValue;
        } else {
            return defaultValue;
        }
    }

    /// Gets the licensor address for this IPA.
    function _getLicensor(
        address ipOrg_,
        address caller_,
        uint256 parentLicenseId_,
        uint256 ipaId_
    ) private view returns (address) {
        Licensing.LicensorConfig licensorConfig = _licensorConfig[ipOrg_];
        if (licensorConfig == Licensing.LicensorConfig.Unset) {
            revert Errors.LicensingModule_IpOrgFrameworkNotSet();
        }
        if (licensorConfig == Licensing.LicensorConfig.IpOrgOwnerAlways) {
            return IIPOrg(ipOrg_).owner();
        } else if (
            licensorConfig == Licensing.LicensorConfig.ParentOrIpaOrIpOrgOwners
        ) {
            if (parentLicenseId_ != 0) {
                return LICENSE_REGISTRY.ownerOf(parentLicenseId_);
            } else if (ipaId_ != 0) {
                return IPA_REGISTRY.ipAssetOwner(ipaId_);
            } else {
                return IIPOrg(ipOrg_).owner();
            }
        }

        revert Errors.LicensingModule_InvalidLicensorConfig();
    }

    ////////////////////////////////////////////////////////////////////////////
    //                              Config                                    //
    ////////////////////////////////////////////////////////////////////////////

    /// Module entrypoint for configuration. It allows an IPOrg to set licensing term
    function _configure(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) internal virtual override returns (bytes memory) {
        // TODO: Revert if terms already exist
        (bytes32 configType, bytes memory configData) = abi.decode(
            params_,
            (bytes32, bytes)
        );
        if (configType == Licensing.LICENSING_FRAMEWORK_CONFIG) {
            return _setIpOrgFramework(ipOrg_, caller_, configData);
        } else {
            // TODO: We need to define if a license holder can modify the terms of a license
        }
        revert Errors.LicensingModule_InvalidConfigType();
    }

    ////////////////////////////////////////////////////////////////////////////
    //                              ipOrgConfig                               //
    ////////////////////////////////////////////////////////////////////////////

    /// Gets commercial and non-commercial terms, and checks for misconfigurations in them before
    // setting them
    /// @param ipOrg_ the ipOrg contract interface
    /// @param caller_ address requesting execution
    /// @param params_ encoded Licensing.FrameworkConfig struct
    function _setIpOrgFramework(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) internal virtual returns (bytes memory) {
        if (ipOrg_.owner() != caller_) {
            revert Errors.LicensingModule_CallerNotIpOrgOwner();
        }
        Licensing.LicensingConfig memory config = abi.decode(
            params_,
            (Licensing.LicensingConfig)
        );
        if (config.licensor == Licensing.LicensorConfig.Unset) {
            revert Errors.LicensingModule_InvalidLicensorConfig();
        }
        address ipOrgAddress = address(ipOrg_);
        if (_licensorConfig[ipOrgAddress] != Licensing.LicensorConfig.Unset) {
            revert Errors.LicensingModule_IpOrgFrameworkAlreadySet();
        }
        if (
            !LICENSING_FRAMEWORK_REPO.validateParamValues(
                config.frameworkId,
                config.params
            )
        ) {
            revert Errors.LicensingModule_InvalidParamValues();
        }

        _licensorConfig[ipOrgAddress] = config.licensor;
        _ipOrgFrameworkIds[ipOrgAddress] = config.frameworkId;

        mapping(ShortString => bytes) storage paramValues = _ipOrgParamValues[
            ipOrgAddress
        ];
        uint256 numParams = config.params.length;
        for (uint256 i = 0; i < numParams; i++) {
            paramValues[config.params[i].tag] = config.params[i].value;
            emit ParameterSet(
                ipOrgAddress,
                config.params[i].tag.toString(),
                config.params[i].value
            );
        }
        emit IpOrgLicensingFrameworkSet(
            ipOrgAddress,
            config.frameworkId,
            LICENSING_FRAMEWORK_REPO.getLicenseTextUrl(config.frameworkId),
            config.licensor
        );
        return "";
    }

    ////////////////////////////////////////////////////////////////////////////
    //                              Hooks                                     //
    ////////////////////////////////////////////////////////////////////////////

    function _hookRegistryKey(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) internal view virtual override returns (bytes32) {
        return keccak256("TODO");
    }
}
