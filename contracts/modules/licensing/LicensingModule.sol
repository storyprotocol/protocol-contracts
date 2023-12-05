// SPDX-License-Identifier: BUSL-1.1
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
// import { TermIds } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
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

    event IpOrgLicensingFrameworkSet (
        address indexed ipOrg,
        string frameworkId,
        string url,
        Licensing.LicensorConfig licensorConfig
    );

    event ParameterSet (
        address indexed ipOrg,
        string paramTag,
        bytes defaultValue
    );

    /// @notice Holds the supported paramerter tags for each ipOrg, and the default values
    /// ipOrg -> paramTag -> bytes
    // TODO(ramarti): optimize for only 1 sload
    mapping(address => mapping(ShortString => bytes)) private _ipOrgParamValues;
    mapping(address => Licensing.LicensorConfig) private _licensorConfig;
    

    LicensingFrameworkRepo public immutable LICENSING_FRAMEWORK_REPO;

    constructor(ModuleConstruction memory params_, address licFrameworkRepo_) BaseModule(params_) {
        if (licFrameworkRepo_ == address(0)) {
            revert Errors.ZeroAddress();
        }  
        LICENSING_FRAMEWORK_REPO = LicensingFrameworkRepo(licFrameworkRepo_);
    }

    function getIpOrgLicensorConfig(address ipOrg_) external view returns (Licensing.LicensorConfig) {
        return _licensorConfig[ipOrg_];
    }

    function getDefaultValueForParam(address ipOrg_, string calldata paramTag_) external view returns (bytes memory) {
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
        // At least non commercial terms must be set
        
        (bytes32 action, bytes memory params) = abi.decode(
            params_,
            (bytes32, bytes)
        );
        if (action == Licensing.CREATE_LICENSE) {
            _verifyCreateLicense(ipOrg_, caller_, params);
        } else if (action != Licensing.ACTIVATE_LICENSE && action != Licensing.LINK_LNFT_TO_IPA) {
            revert Errors.LicensingModule_InvalidAction();
        }
    }
    
    function _verifyCreateLicense(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) private view {
        (
            Licensing.LicenseCreation memory lParams,
            bytes memory data
        ) = abi.decode(
                params_,
                (Licensing.LicenseCreation, Licensing.LicenseeType, bytes)
            );
        
        // ------ Derivative license checks ------
        if (lParams.parentLicenseId != 0) {
   
            // If no share alike, only the parent licensee can create a derivative license
            if (
                !_shareAlike[
                    _getTermsKey(lParams.isCommercial, address(ipOrg_))
                ]
            ) {
                if (
                    caller_ !=
                    LICENSE_REGISTRY.getLicensee(lParams.parentLicenseId)
                ) {
                    revert Errors.LicensingModule_ShareAlikeDisabled();
                }
            }
        }
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
            return _createLicense(ipOrg_, caller_, actionParams);
        } else if (action == Licensing.ACTIVATE_LICENSE) {
            uint256 licenseId = abi.decode(actionParams, (uint256));
            LICENSE_REGISTRY.activateLicense(licenseId, caller_);
            return bytes("");
        } else if (action == Licensing.LINK_LNFT_TO_IPA) {
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
        (
            Licensing.LicenseCreation memory lParams,
            Licensing.LicenseeType licenseeType,
            bytes memory data
        ) = abi.decode(
                params_,
                (Licensing.LicenseCreation, Licensing.LicenseeType, bytes)
            );

        uint256 ipaId = Licensing.LicenseeType.BoundToIpa == licenseeType
            ? abi.decode(data, (uint256))
            : 0;
        // TODO: compose IpOrg terms with user provider Terms
        Licensing.RegistryAddition memory rParams = _getRegistryAddition(
            lParams,
            address(ipOrg_),
            ipaId
        );
        uint256 licenseId;
        // Create the licenses
        if (licenseeType == Licensing.LicenseeType.BoundToIpa) {
            licenseId = LICENSE_REGISTRY.addBoundToIpaLicense(
                rParams,
                abi.decode(data, (uint256))
            );
        } else {
            licenseId = LICENSE_REGISTRY.addTradeableLicense(
                rParams,
                abi.decode(data, (address))
            );
        }
        return abi.encode(licenseId);
    }

    function _getRegistryAddition(
        Licensing.LicenseCreation memory lParams_,
        address ipOrg_,
        uint256 ipaId_
    ) private view returns (Licensing.RegistryAddition memory) {
        bytes32 termsKey = _getTermsKey(lParams_.isCommercial, ipOrg_);
        ShortString[] memory termIds = _ipOrgTermIds[termsKey].values();
        bytes[] memory termsData = _ipOrgTermData[termsKey];
        Licensing.LicenseStatus status = Licensing.LicenseStatus.Active;
        if (_licensorApprovalNeeded[termsKey]) {
            status = Licensing.LicenseStatus.Pending;
        }
        return
            Licensing.RegistryAddition({
                isCommercial: lParams_.isCommercial,
                status: status,
                licensor: _getLicensor(
                    lParams_.parentLicenseId,
                    ipaId_,
                    lParams_.isCommercial,
                    ipOrg_
                ),
                revoker: _getRevoker(ipOrg_),
                ipOrg: ipOrg_,
                parentLicenseId: lParams_.parentLicenseId,
                termIds: termIds,
                termsData: termsData
            });
    }

    function _activateLicense(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) private returns (bytes memory result) {
        uint256 licenseId = abi.decode(params_, (uint256));
        
        Licensing.License memory license = LICENSE_REGISTRY.getLicense(
            licenseId
        );
        // For now, we just support activating license with an explicit approval from
        // Licensor. TODO: support more activation terms
        
    }

    /// Gets the licensor address for this IPA.
    function _getLicensor(
        uint256 parentLicenseId_,
        uint256 ipa_,
        bool commercial_,
        address ipOrg_
    ) private view returns (address) {
        // TODO: Check for Licensor term in terms registry.
        TermsData.LicensorConfig licensorConfig = _licensorConfig[
            _getTermsKey(commercial_, ipOrg_)
        ];
        if (licensorConfig == TermsData.LicensorConfig.IpOrg) {
            return IIPOrg(ipOrg_).owner();
        } else if (licensorConfig == TermsData.LicensorConfig.ParentLicensee) {
            if (parentLicenseId_ == 0) {
                if (ipa_ == 0) {
                    revert Errors
                        .LicensingModule_CantFindParentLicenseOrRelatedIpa();
                }
                return IPA_REGISTRY.ipAssetOwner(ipa_);
            } else {
                return LICENSE_REGISTRY.getLicensee(parentLicenseId_);
            }
        } else {
            revert Errors.LicensingModule_InvalidLicensorType();
        }
    }

    /// Gets the revoker address for this IPOrg.
    function _getRevoker(address ipOrg) private view returns (address) {
        // TODO: Check Revoker term in terms registry to chose disputer
        // For now, ipOrgOwner
        return IIPOrg(ipOrg).owner();
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
        if (!LICENSING_FRAMEWORK_REPO.validateParamValues(config.frameworkId, config.params)) {
            revert Errors.LicensingModule_InvalidParamValues();
        }
        
        _licensorConfig[ipOrgAddress] = config.licensor;

        mapping(ShortString => bytes) storage paramValues = _ipOrgParamValues[ipOrgAddress];
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
