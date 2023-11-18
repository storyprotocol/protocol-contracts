// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { RelationshipModule } from "../relationships/RelationshipModule.sol";
import { TermsRepository } from "./TermsRepository.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { TermIds, TermsData } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";


/// @title License Creator module
/// @notice Story Protocol module that:
/// - Enables each IP Org to select a collection of terms from the TermsRepository to form
///   their licensing framework.
/// - Enables Other modules to attach licensing terms to IPAs
/// - Enables license holders to create derivative licenses
/// Thanks to ERC-5218 authors for inspiration (see https://eips.ethereum.org/EIPS/eip-5218)
contract LicensingModule is BaseModule, TermsRepository {
    using ShortStrings for *;
    using FixedSet for FixedSet.ShortStringSet;

    // NOTE: emitting this event can be very expensive, check if terms can be indexed some
    // other way
    event IpOrgTermsSet(
        address indexed ipOrg,
        bool commercial,
        ShortString[] termIds,
        bytes[] termData
    );

    /// Per ipOrg licensing term Ids.
    mapping(bytes32 => FixedSet.ShortStringSet) private _ipOrgTermIds;
    /// Per ipOrg data to configure licensing terms, corresponding to the ids.
    mapping(bytes32 => bytes[]) private _ipOrgTermData;
    mapping(bytes32 => bool) private _shareAlike;
    mapping(bytes32 => TermsData.LicensorConfig) private _licensorConfig;
    // TODO: support different activation terms on chain
    mapping(bytes32 => bool) private _licensorApprovalNeeded;

    constructor(ModuleConstruction memory params_) BaseModule(params_) {}

    /// Returns true if the share alike term is on for this ipOrg and commercial status,
    function isShareAlikeOn(
        bool commercial_,
        address ipOrg_
    ) external view returns (bool) {
        return _shareAlike[_getTermsKey(commercial_, ipOrg_)];
    }

    /// Returns the licensor config for an ipOrg and commercial status
    function getLicensorConfig(
        bool commercial_,
        address ipOrg_
    ) external view returns (TermsData.LicensorConfig) {
        return _licensorConfig[_getTermsKey(commercial_, ipOrg_)];
    }

    /// Returns true if the licensor approval is needed for this ipOrg and commercial
    /// status, false otherwise
    function isLicensorAppovalOn(
        bool commercial_,
        address ipOrg_
    ) external view returns (bool) {
        return _licensorApprovalNeeded[_getTermsKey(commercial_, ipOrg_)];
    }

    /// Returns true if the ipOrg has commercial terms configured, false otherwise
    function ipOrgAllowsCommercial(address ipOrg_) public view returns (bool) {
        return _ipOrgTermIds[_getTermsKey(true, ipOrg_)].length() > 0;
    }

    /// Get all term ids configured for an ipOrg, along the config data
    /// @dev WARNING: this will copy all term ids to memory, it can be expensive
    function getIpOrgTerms(
        bool commercial_,
        address ipOrg_
    ) public view returns (ShortString[] memory, bytes[] memory) {
        return (
            _ipOrgTermIds[_getTermsKey(commercial_, ipOrg_)].values(),
            _ipOrgTermData[_getTermsKey(commercial_, ipOrg_)]
        );
    }

    /// Get the number of terms configured for an ipOrg
    /// @param commercial_ true for commercial terms, false for non-commercial terms
    /// @param ipOrg_ the ipOrg address
    /// @return the number of terms configured for the ipOrg
    function getTotalIpOrgTerms(
        bool commercial_,
        address ipOrg_
    ) public view returns (uint256) {
        return _ipOrgTermIds[_getTermsKey(commercial_, ipOrg_)].length();
    }

    /// Check if an ipOrg has a term configured
    /// @param commercial_ true for commercial terms, false for non-commercial terms
    /// @param ipOrg_ the ipOrg address
    /// @param termId_ the term id
    /// @return true if the term is configured, false otherwise
    function ipOrgTermsContains(
        bool commercial_,
        address ipOrg_,
        ShortString termId_
    ) public view returns (bool) {
        return
            _ipOrgTermIds[_getTermsKey(commercial_, ipOrg_)].contains(termId_);
    }

    /// Get the data for a term configured for an ipOrg
    /// @dev method will revert if the term is not configured
    /// @param commercial_ true for commercial terms, false for non-commercial terms
    /// @param ipOrg_ the ipOrg address
    /// @param termId_ the term id
    /// @return the term data
    function ipOrgTermData(
        bool commercial_,
        address ipOrg_,
        ShortString termId_
    ) public view returns (bytes memory) {
        bytes32 key = _getTermsKey(commercial_, ipOrg_);
        FixedSet.ShortStringSet storage termIds = _ipOrgTermIds[key];
        bytes[] storage termData = _ipOrgTermData[key];
        uint256 index = termIds.indexOf(termId_);
        if (index == FixedSet.INDEX_NOT_FOUND) {
            revert Errors.LicensingModule_ipOrgTermNotFound();
        }
        return termData[index];
    }

    /// Gets the pair of ipOrg term Id and data at a certain index
    /// @param commercial_ true for commercial terms, false for non-commercial terms
    /// @param ipOrg_ the ipOrg address
    /// @param index_ the index
    /// @return termId term Id
    /// @return data the term data
    function ipOrgTermsAt(
        bool commercial_,
        address ipOrg_,
        uint index_
    ) public view returns (ShortString termId, bytes memory data) {
        bytes32 key = _getTermsKey(commercial_, ipOrg_);
        return (_ipOrgTermIds[key].at(index_), _ipOrgTermData[key][index_]);
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
        if (getTotalIpOrgTerms(false, address(ipOrg_)) == 0) {
            revert Errors.LicensingModule_IpOrgNotConfigured();
        }
        (bytes32 action, bytes memory params) = abi.decode(
            params_,
            (bytes32, bytes)
        );
        if (action == Licensing.CREATE_LICENSE) {
            _verifyCreateLicense(ipOrg_, caller_, params);
        } else if (action == Licensing.ACTIVATE_LICENSE) {
            _verifyActivateLicense(ipOrg_, caller_, params);
        } else if (action == Licensing.BOND_LNFT_TO_IPA) {
            _verifyBondNftToIpa(ipOrg_, caller_, params);
        } else {
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
            Licensing.LicenseeType licenseeType,
            bytes memory data
        ) = abi.decode(
                params_,
                (Licensing.LicenseCreation, Licensing.LicenseeType, bytes)
            );
        // ------ Commercial status checks ------
        if (!ipOrgAllowsCommercial(address(ipOrg_)) && lParams.isCommercial) {
            revert Errors.LicensingModule_CommercialLicenseNotAllowed();
        }
        // ------ Misconfiguration ------
        if (licenseeType == Licensing.LicenseeType.Unset) {
            revert Errors.LicensingModule_InvalidLicenseeType();
        }
        // ------ Derivative license checks ------
        if (lParams.parentLicenseId != 0) {
            if (!LICENSE_REGISTRY.isLicenseActive(lParams.parentLicenseId)) {
                revert Errors.LicensingModule_ParentLicenseNotActive();
            }
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

    function _verifyActivateLicense(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) private view {
        uint256 licenseId = abi.decode(params_, (uint256));
        Licensing.License memory license = LICENSE_REGISTRY.getLicense(
            licenseId
        );
        if (caller_ != license.licensor) {
            revert Errors.LicensingModule_CallerNotLicensor();
        }
        if (
            license.parentLicenseId != 0 &&
            !LICENSE_REGISTRY.isLicenseActive(license.parentLicenseId)
        ) {
            revert Errors.LicensingModule_ParentLicenseNotActive();
        }
    }

    function _verifyBondNftToIpa(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) private view {
        (uint256 licenseId, uint256 ipaId) = abi.decode(
            params_,
            (uint256, uint256)
        );
        if (caller_ != LICENSE_REGISTRY.ownerOf(licenseId)) {
            revert Errors.LicensingModule_CallerNotLicenseOwner();
        }
        if (!LICENSE_REGISTRY.isLicenseActive(licenseId)) {
            revert Errors.LicensingModule_ParentLicenseNotActive();
        }
        if (IPA_REGISTRY.status(ipaId) == 0) {
            revert Errors.LicensingModule_InvalidIpa();
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
            return _activateLicense(ipOrg_, caller_, actionParams);
        } else if (action == Licensing.BOND_LNFT_TO_IPA) {
            (uint256 licenseId, uint256 ipaId) = abi.decode(
                actionParams,
                (uint256, uint256)
            );
            LICENSE_REGISTRY.bondLnftToIpa(licenseId, ipaId);
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
        LICENSE_REGISTRY.activateLicense(licenseId);
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
        address ipOrgAddress = address(ipOrg_);

        Licensing.FrameworkConfig memory framework = abi.decode(
            params_,
            (Licensing.FrameworkConfig)
        );

        // Set non-commercial terms
        Licensing.TermsConfig memory nonComTermsConfig = framework
            .nonComTermsConfig;
        // IP Org has to have non-commercial terms
        if (nonComTermsConfig.termIds.length == 0) {
            revert Errors.LicensingModule_NonCommercialTermsRequired();
        }
        bytes32 nonComKey = _getTermsKey(false, ipOrgAddress);
        bytes[] storage nonComTermData = _ipOrgTermData[nonComKey];
        FixedSet.ShortStringSet storage nonComTermIds = _ipOrgTermIds[
            nonComKey
        ];
        if (nonComTermIds.length() > 0) {
            // We assume an ipOrg licensing framework cannot change, so if the terms are not empty
            // we revert
            revert Errors.LicensingModule_IpOrgFrameworkAlreadySet();
        }
        _setTerms(
            false,
            nonComKey,
            nonComTermsConfig,
            nonComTermIds,
            nonComTermData
        );
        emit IpOrgTermsSet(
            ipOrgAddress,
            false,
            nonComTermIds.values(),
            nonComTermData
        );

        Licensing.TermsConfig memory comTermsConfig = framework.comTermsConfig;
        // Set commercial terms
        bytes32 comKey = _getTermsKey(true, ipOrgAddress);
        bytes[] storage comTermData = _ipOrgTermData[comKey];
        FixedSet.ShortStringSet storage comTermIds = _ipOrgTermIds[comKey];
        _setTerms(true, comKey, comTermsConfig, comTermIds, comTermData);
        emit IpOrgTermsSet(
            ipOrgAddress,
            true,
            comTermIds.values(),
            comTermData
        );

        return "";
    }

    /// Validate input licensing terms and populate ipOrg licensing framework
    /// @param commercial_ true for commercial terms, false for non-commercial terms
    /// @param termsKey_ key to the ipOrg terms
    /// @param termsConfig_ arrays for termIds and their ipOrg level config data
    /// @param ipOrgTermIds_ ipOrg terms set, where the termIds will be added
    /// @param ipOrgTermData_ ipOrg config data for terms, where the term data will be added
    function _setTerms(
        bool commercial_,
        bytes32 termsKey_,
        Licensing.TermsConfig memory termsConfig_,
        FixedSet.ShortStringSet storage ipOrgTermIds_,
        bytes[] storage ipOrgTermData_
    ) internal {
        uint256 termsLength = termsConfig_.termIds.length;
        for (uint256 i = 0; i < termsLength; i++) {
            ShortString termId = termsConfig_.termIds[i];
            if (ipOrgTermIds_.contains(termId)) {
                revert Errors.LicensingModule_DuplicateTermId();
            }
            Licensing.LicensingTerm memory term = getTerm(termId);
            // Since there is CommercialStatus.Both, we need to be specific here
            if (
                (commercial_ &&
                    term.comStatus ==
                    Licensing.CommercialStatus.NonCommercial) ||
                (!commercial_ &&
                    term.comStatus == Licensing.CommercialStatus.Commercial)
            ) {
                // We assume that CommercialStatus.Unset is not possible, since
                // TermsRepository checks for that
                revert Errors.LicensingModule_InvalidTermCommercialStatus();
            }
            bytes memory data = termsConfig_.termData[i];
            if (ShortStringOps._equal(termId, TermIds.NFT_SHARE_ALIKE)) {
                _shareAlike[termsKey_] = abi.decode(data, (bool));
            } else if (
                ShortStringOps._equal(termId, TermIds.LICENSOR_IPORG_OR_PARENT)
            ) {
                _licensorConfig[termsKey_] = abi.decode(
                    data,
                    (TermsData.LicensorConfig)
                );
            } else if (
                ShortStringOps._equal(termId, TermIds.LICENSOR_APPROVAL)
            ) {
                _licensorApprovalNeeded[termsKey_] = abi.decode(data, (bool));
            }

            // TODO: support hooks
            ipOrgTermIds_.add(termId);
            ipOrgTermData_.push(data);
        }
    }

    function _getTermsKey(
        bool commercial_,
        address ipOrg_
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(ipOrg_, commercial_));
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
