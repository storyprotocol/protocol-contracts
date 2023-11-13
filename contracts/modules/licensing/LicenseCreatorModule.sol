// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { ProtocolRelationships } from "contracts/lib/modules/ProtocolRelationships.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { RelationshipModule } from "../relationships/RelationshipModule.sol";
import { TermsRepository } from "./TermsRepository.sol";
import { ProtocolTermsHelper } from "./ProtocolTermsHelper.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

import "forge-std/console.sol";

contract LicenseCreatorModule is BaseModule, TermsRepository, ProtocolTermsHelper {
    using ShortStrings for *;
    using FixedSet for FixedSet.ShortStringSet;

    // NOTE: emitting this event can be very expensive, check if terms can be indexed some
    // other way
    event IpOrgTermsSet(address indexed ipOrg, bool commercial, ShortString[] termIds, bytes[] termData);

    RelationshipModule public immutable RELATIONSHIP_MODULE;
    mapping(address => FixedSet.ShortStringSet) private _comIpOrgTermIds;
    mapping(address => bytes[]) private _comIpOrgTermData;
    mapping(address => FixedSet.ShortStringSet) private _nonComIpOrgTermIds;
    mapping(address => bytes[]) private _nonComIpOrgTermData;

    constructor(ModuleConstruction memory params_) BaseModule(params_) {
        RELATIONSHIP_MODULE = RelationshipModule(
            address(
                MODULE_REGISTRY.moduleForKey(
                    ModuleRegistryKeys.RELATIONSHIP_MODULE
                )
            )
        );
    }

    function ipOrgAllowsCommercial(address ipOrg_) public view returns (bool) {
        return _comIpOrgTermIds[ipOrg_].length() > 0;
    }

    // NOTE: this will copy all terms to memory, it can be expensive
    function getIpOrgTerms(bool commercial, address ipOrg_) public view returns (ShortString[] memory, bytes[] memory) {
        if (commercial) {
            return (
                _comIpOrgTermIds[ipOrg_].values(),
                _comIpOrgTermData[ipOrg_]
            );
        } else {
            return (
                _nonComIpOrgTermIds[ipOrg_].values(),
                _nonComIpOrgTermData[ipOrg_]
            );
        }
    }

    function getTotalIpOrgTerms(bool commercial, address ipOrg_) public view returns (uint256) {
        if (commercial) {
            return _comIpOrgTermIds[ipOrg_].length();
        } else {
            return _nonComIpOrgTermIds[ipOrg_].length();
        }
    }

    function ipOrgTermsAt(bool commercial, address ipOrg_, uint index_) public view returns (ShortString termId, bytes memory data) {
        if (commercial) {
            return (_comIpOrgTermIds[ipOrg_].at(index_), _comIpOrgTermData[ipOrg_][index_]);
        } else {
            return (_nonComIpOrgTermIds[ipOrg_].at(index_), _nonComIpOrgTermData[ipOrg_][index_]);
        }
    }

    function _hookRegistryAdmin()
        internal
        view
        virtual
        override
        returns (address)
    {
        return address(0);
    }

    ////////////////////////////////////////////////////////////////////////////
    //                          Create License                                //
    ////////////////////////////////////////////////////////////////////////////

    function _verifyExecution(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) virtual internal override {
        Licensing.LicenseCreationParams memory lParams = abi.decode(
            params_,
            (Licensing.LicenseCreationParams)
        );
        // If creating license for root IPA:
        if (lParams.parentLicenseId == 0) {
            if (lParams.ipaId == 0) {
                revert Errors.LicensingModule_IpaIdRequired();
            }
            if (ipOrg_.owner() != caller_) {
                revert Errors.LicensingModule_CallerNotIpOrgOwner();
            }
        } else {
            // TODO: Check if parent license is active
            
        }
        
        // At least non commercial terms must be set
        if (_nonComIpOrgTermData[address(ipOrg_)].length == 0) {
            revert Errors.LicensingModule_IpOrgNotConfigured();
        }
        if (!ipOrgAllowsCommercial(address(ipOrg_)) && lParams.isCommercial) {
            revert Errors.LicensingModule_CommercialLicenseNotAllowed();
        }
        if (lParams.ipaId != 0) {
            // Todo: define status types
            if (IPA_REGISTRY.ipAssetStatus(lParams.ipaId) != 1) {
                revert Errors.LicensingModule_IpaNotActive();
            }
            //TODO Check if IPA has a license already
        }
    }

    function _performAction(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) virtual internal override returns (bytes memory result) {
        Licensing.LicenseCreationParams memory lParams = abi.decode(
            params_,
            (Licensing.LicenseCreationParams)
        );
        // TODO: How do we distinguish which terms apply?
        // Share alike and Remix IPA, posting the remixed IPA => copy parent license terms?
        // License to make an remixed IPA in the future => ????
        // License to commercialize IPA => ???
        // Commerial license to use IPA in IPA => ???
        IPAsset.IPA memory ipa = IPA_REGISTRY.getIpAsset(lParams.ipaId);
        (ShortString[] memory termIds, bytes[] memory termsData) = getIpOrgTerms(
            lParams.isCommercial,
            address(ipOrg_)
        );

        Licensing.License memory license = Licensing.License({
            isCommercial: lParams.isCommercial,
            licenseeType: _getLicenseeType(lParams.ipaId),
            licensor: _getLicensor(
                ipOrg_.owner(),
                ipa.owner,
                LICENSE_REGISTRY.getLicensee(lParams.parentLicenseId)
            ),
            revoker: _getRevoker(ipOrg_),
            termIds: termIds,
            termsData: termsData
        });
        uint256 licenseId = LICENSE_REGISTRY.addLicense(license, caller_);
        if (lParams.ipaId != 0) {
            _relateToIpa(lParams.ipaId, licenseId);
        }
        if (lParams.parentLicenseId != 0) {
            _relateToParentLicense(lParams.parentLicenseId, licenseId);
        }
        return abi.encode(licenseId);
    }

    function _getLicenseeType(uint256 ipaId) private pure returns (Licensing.LicenseeType) {
        if (ipaId == 0) {
            return Licensing.LicenseeType.LNFTHolder;
        }
        return Licensing.LicenseeType.BoundToIpa;
    }

    function _relateToIpa(uint256 ipaId, uint256 licenseId) private returns (uint256) {
        return _createRelationship(
            LibRelationship.CreateRelationshipParams({
                relType: ProtocolRelationships.IPA_LICENSE,
                srcAddress: address(LICENSE_REGISTRY),
                srcId: licenseId,
                srcType: 0,
                dstAddress: address(IPA_REGISTRY),
                dstId: ipaId,
                dstType: 0
            })
        );
    }

    function _relateToParentLicense(uint256 parentLicenseId, uint256 licenseId) private returns (uint256) {
        return _createRelationship(
            LibRelationship.CreateRelationshipParams({
                relType: ProtocolRelationships.SUBLICENSE_OF,
                srcAddress: address(LICENSE_REGISTRY),
                srcId: licenseId,
                srcType: 0,
                dstAddress: address(LICENSE_REGISTRY),
                dstId: parentLicenseId,
                dstType: 0
            })
        );
    }

    function _getLicensor(
        address ipOrgOwner,
        address ipaOwner,
        address parentLicenseOwner
    ) private view returns (address) {
        // TODO: Check for Licensor term in terms registry.
        if (parentLicenseOwner != address(0)) {
            return parentLicenseOwner;
        }
        return ipaOwner;
    }

    function _getRevoker(IIPOrg ipOrg) private view returns (address) {
        // TODO: Check Revoker term in terms registry to chose disputer
        // For now, ipOrgOwner
        return ipOrg.owner();
    }

    ////////////////////////////////////////////////////////////////////////////
    //                              Config                                    //
    ////////////////////////////////////////////////////////////////////////////


    function _configure(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) virtual override internal returns (bytes memory) {

        // TODO: Revert if terms already exist
        (bytes32 configType, bytes memory configData) = abi.decode(params_, (bytes32, bytes));
        if (configType == Licensing.LICENSING_FRAMEWORK_CONFIG) {
            return _setIpOrgFramework(ipOrg_, caller_, configData);
        } else {
            // TODO: check if caller is License holder and can modify something from his license?
        }
        revert Errors.LicensingModule_InvalidConfigType();
    }

    ////////////////////////////////////////////////////////////////////////////
    //                              ipOrgConfig                               //
    ////////////////////////////////////////////////////////////////////////////

    function _setIpOrgFramework(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) virtual internal returns (bytes memory) {
        if (ipOrg_.owner() != caller_) {
            revert Errors.LicensingModule_CallerNotIpOrgOwner();
        }        
        address ipOrgAddress = address(ipOrg_);

        Licensing.FrameworkConfig memory framework = abi.decode(params_, (Licensing.FrameworkConfig));

        // Set non-commercial terms
        Licensing.TermsConfig memory nonComTermsConfig = framework.nonComTermsConfig;
        if (nonComTermsConfig.termIds.length == 0) {
            revert Errors.LicensingModule_NonCommercialTermsRequired();
        }
        bytes[] storage nonComTermData = _nonComIpOrgTermData[ipOrgAddress];
        FixedSet.ShortStringSet storage nonComTermIds = _nonComIpOrgTermIds[ipOrgAddress];
        if (nonComTermIds.length() > 0) {
            // We assume ipOrg config is immutable, licensing changes in an ipOrg imply a fork
            revert Errors.LicensingModule_IpOrgFrameworkAlreadySet();
        }
        _setTerms(false, nonComTermsConfig, nonComTermIds, nonComTermData);
        emit IpOrgTermsSet(ipOrgAddress, false, nonComTermIds.values(), nonComTermData);
        
        Licensing.TermsConfig memory comTermsConfig = framework.comTermsConfig;
        // Set commercial terms
        bytes[] storage comTermData = _comIpOrgTermData[ipOrgAddress];
        FixedSet.ShortStringSet storage comTermIds = _comIpOrgTermIds[ipOrgAddress];
        _setTerms(true, comTermsConfig, comTermIds, comTermData);
        emit IpOrgTermsSet(ipOrgAddress, true, comTermIds.values(), comTermData);
        
        return "";
    }

    function _setTerms(
        bool commercial,
        Licensing.TermsConfig memory termsConfig_,
        FixedSet.ShortStringSet storage termIds_,
        bytes[] storage ipOrgTermData_
    ) internal {
        uint256 termsLength = termsConfig_.termIds.length;
        for (uint256 i = 0; i < termsLength; i++) {
            ShortString termId = termsConfig_.termIds[i];
            if (termIds_.contains(termId)) {
                revert Errors.LicensingModule_DuplicateTermId();
            }
            Licensing.LicensingTerm memory term = getTerm(termId);
            // Since there is CommercialStatus.Both, we need to be specific here
            if (
                commercial && term.comStatus == Licensing.CommercialStatus.NonCommercial ||
                !commercial && term.comStatus == Licensing.CommercialStatus.Commercial
            ) {
                // We assume that CommercialStatus.Unset is not possible, since 
                // TermsRepository checks for that
                revert Errors.LicensingModule_InvalidTermCommercialStatus();
            }
            bytes memory data = termsConfig_.termData[i];
            if (address(term.hook) != address(0)) {
                // Reverts if decoding fails
                term.hook.validateConfig(abi.encode(termId, data));
            }
            termIds_.add(termId);
            ipOrgTermData_.push(data);
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    //                              Relationships                             //
    ////////////////////////////////////////////////////////////////////////////

    function _createRelationship(
        LibRelationship.CreateRelationshipParams memory newRelParams
    ) private returns (uint256 relId){
        relId = abi.decode(
            MODULE_REGISTRY.execute(
                IIPOrg(LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP),
                ModuleRegistryKeys.RELATIONSHIP_MODULE,
                abi.encode(newRelParams),
                new bytes[](0),
                new bytes[](0)
            ),
            (uint256)
        );
        return relId;
    }

}
