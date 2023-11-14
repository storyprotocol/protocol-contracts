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
import { TermIds, TermData } from "contracts/lib/modules/ProtocolLicensingTerms.sol";


contract LicenseCreatorModule is BaseModule, TermsRepository {
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

    function getTotalIpOrgTerms(bool commercial_, address ipOrg_) public view returns (uint256) {
        if (commercial_) {
            return _comIpOrgTermIds[ipOrg_].length();
        } else {
            return _nonComIpOrgTermIds[ipOrg_].length();
        }
    }

    function ipOrgTermsContains(bool commercial_, address ipOrg_, ShortString termId) public view returns (bool) {
        if (commercial_) {
            return _comIpOrgTermIds[ipOrg_].contains(termId);
        } else {
            return _nonComIpOrgTermIds[ipOrg_].contains(termId);
        }
    }

    function ipOrgTermData(bool commercial_, address ipOrg_, ShortString termId) public view returns (bytes memory) {
        if (commercial_) {
            uint256 index = _comIpOrgTermIds[ipOrg_].indexOf(termId);
            if (index == type(uint256).max) {
                revert Errors.LicensingModule_ipOrgTermNotFound();
            }
            return _comIpOrgTermData[ipOrg_][index];
        } else {
            uint256 index = _nonComIpOrgTermIds[ipOrg_].indexOf(termId);
            if (index == type(uint256).max) {
                revert Errors.LicensingModule_ipOrgTermNotFound();
            }
            return _nonComIpOrgTermData[ipOrg_][index];
        }
    }

    function ipOrgTermsAt(bool commercial_, address ipOrg_, uint index_) public view returns (ShortString termId, bytes memory data) {
        if (commercial_) {
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
        (
            Licensing.LicenseCreation memory lParams,
            Licensing.LicenseeType licenseeType,
            bytes memory data
        ) = abi.decode(
            params_,
            (
                Licensing.LicenseCreation,
                Licensing.LicenseeType,
                bytes
            )
        );
        // At least non commercial terms must be set
        if (_nonComIpOrgTermData[address(ipOrg_)].length == 0) {
            revert Errors.LicensingModule_IpOrgNotConfigured();
        }
        // ------ Commercial status checks ------
        if (!ipOrgAllowsCommercial(address(ipOrg_)) && lParams.isCommercial) {
            revert Errors.LicensingModule_CommercialLicenseNotAllowed();
        }
        if (licenseeType == Licensing.LicenseeType.Unset) {
            revert Errors.LicensingModule_InvalidLicenseeType();
        }
        // ------ Root Ipa checks ------
        if (lParams.parentLicenseId == 0) {
            if (ipOrg_.owner() != caller_) {
                revert Errors.LicensingModule_CallerNotIpOrgOwner();
            }
        } else {
        // ------ Derivative license checks ------
            FixedSet.ShortStringSet storage termIds = _getIpOrgTermIds(lParams.isCommercial, address(ipOrg_));
            bytes[] storage termData = _getIpOrgTermData(lParams.isCommercial, address(ipOrg_));
            uint256 nftShareAlikeIndex = termIds.indexOf(TermIds.NFT_SHARE_ALIKE.toShortString());
            // If there is no NFT_SHARE_ALIKE term, or if it is false then we cannot have
            // a derivative license unless caller owns the parent license
            if (nftShareAlikeIndex == FixedSet.INDEX_NOT_FOUND ||
                !abi.decode(termData[nftShareAlikeIndex], (bool))
            ) {
                address parentLicensor = LICENSE_REGISTRY.getLicensor(lParams.parentLicenseId);
                if (parentLicensor != caller_) {
                    revert Errors.LicensingModule_ShareAlikeDisabled();
                }
            }
        }
    }

    function _performAction(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) virtual internal override returns (bytes memory result) {
        (
            Licensing.LicenseCreation memory lParams,
            Licensing.LicenseeType licenseeType,
            bytes memory data
        ) = abi.decode(
            params_,
            (
                Licensing.LicenseCreation,
                Licensing.LicenseeType,
                bytes
            )
        );
        (ShortString[] memory termIds, bytes[] memory termsData) = getIpOrgTerms(
            lParams.isCommercial,
            address(ipOrg_)
        );
        uint256 ipaId = Licensing.LicenseeType.BoundToIpa == licenseeType ? abi.decode(data, (uint256)) : 0;
        // TODO: compose IpOrg terms with user provider Terms
        Licensing.RegistryAddition memory rParams = Licensing.RegistryAddition({
            isCommercial: lParams.isCommercial,
            licensor: _getLicensor(
                ipaId,
                LICENSE_REGISTRY.getLicensor(lParams.parentLicenseId)
            ),
            revoker: _getRevoker(ipOrg_),
            ipOrg: address(ipOrg_),
            parentLicenseId: lParams.parentLicenseId,
            termIds: termIds,
            termsData: termsData,
            data: data
        });
        uint256 licenseId;
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

    function _getLicensor(
        uint256 ipaId,
        address parentLicenseOwner
    ) private view returns (address) {
        // TODO: Check for Licensor term in terms registry.
        if (parentLicenseOwner != address(0) || ipaId == 0) {
            return parentLicenseOwner;
        }
        return IPA_REGISTRY.ipAssetOwner(ipaId);
    }

    function _getRevoker(IIPOrg ipOrg) private view returns (address) {
        // TODO: Check Revoker term in terms registry to chose disputer
        // For now, ipOrgOwner
        return ipOrg.owner();
    }

    function _getIpOrgTermIds(bool commercial, address ipOrg_) private view returns (FixedSet.ShortStringSet storage) {
        if (commercial) {
            return _comIpOrgTermIds[ipOrg_];
        } else {
            return _nonComIpOrgTermIds[ipOrg_];
        }
    }

    function _getIpOrgTermData(bool commercial, address ipOrg_) private view returns (bytes[] storage) {
        if (commercial) {
            return _comIpOrgTermData[ipOrg_];
        } else {
            return _nonComIpOrgTermData[ipOrg_];
        }
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
