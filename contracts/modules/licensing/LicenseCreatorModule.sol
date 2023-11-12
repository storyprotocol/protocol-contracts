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
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

import "forge-std/console.sol";

contract LicenseCreatorModule is BaseModule, TermsRepository, ProtocolTermsHelper {
    using ShortStrings for *;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    event IpOrgTermsSet(address indexed ipOrg, bool commercial, bytes32[] termIds, bytes[] termData);

    RelationshipModule public immutable RELATIONSHIP_MODULE;
    mapping(address => EnumerableSet.Bytes32Set) private _comIpOrgTermIds;
    mapping(address => bytes[]) private _comIpOrgTermData;
    mapping(address => EnumerableSet.Bytes32Set) private _nonComIpOrgTermIds;
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

    function getIpOrgTerms(bool commercial, address ipOrg_) public view returns (bytes32[] memory, bytes[] memory) {
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

    function _hookRegistryAdmin()
        internal
        view
        virtual
        override
        returns (address)
    {
        return address(0);
    }

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
            if (ipOrg_.owner() != caller_) {
                revert Errors.LicensingModule_CallerNotIpOrgOwner();
            }
        } else {
            // TODO: Check if license is active
            
        }
        if (_comIpOrgTermIds[address(ipOrg_)].length() == 0) {
            revert Errors.LicensingModule_IpOrgNotConfigured();
        }
        
        if (!ipOrgAllowsCommercial(address(ipOrg_)) && lParams.isCommercial) {
            revert Errors.LicensingModule_CommercialLicenseNotAllowed();
        }
        if (lParams.ipaId != 0) {
            // Todo: define status types
            if (IPA_REGISTRY.ipAssetStatus(lParams.ipaId) != 1) {
                revert Errors.LicensingModule_IPANotActive();
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
        IPAsset.IPA memory ipa = IPA_REGISTRY.getIpAsset(lParams.ipaId);
        
        Licensing.License memory license = Licensing.License({
            isCommercial: lParams.isCommercial,
            licensor: _getLicensor(
                ipOrg_.owner(),
                ipa.owner,
                LICENSE_REGISTRY.getLicenseOwner(lParams.parentLicenseId)
            ),
            revoker: _getRevoker(address(ipOrg_)),
            termsConfig: new Licensing.TermsConfig[](0)
        });
        return abi.encode(1);
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

    function _getRevoker(address ipOrg) private view returns (address) {
        // TODO: Check Revoker term in terms registry.
        return address(0);
    }

    /*
            (
            uint256 parentLicenseId,
            bytes[] memory additionalTerms,
            uint256 newIpaId
        ) = abi.decode(params_, (uint256, bytes[], uint256));
        
        uint256 licenseId = LICENSE_REGISTRY.createLicenseFrom(parentLicenseId);
        // If we have commercial terms (this is a commercial sublicense or remix)
        if (additionalTerms.length > 0) {
            LICENSE_REGISTRY.addTerms(licenseId, additionalTerms);
        }

        uint256 sublicenseRelId = _createRelationship(
            LibRelationship.CreateRelationshipParams({
                relType: ProtocolRelationships.SUBLICENSE_OF,
                srcAddress: address(LICENSE_REGISTRY),
                srcId: parentLicenseId,
                srcType: 0,
                dstAddress: address(LICENSE_REGISTRY),
                dstId: licenseId,
                dstType: 0
            })
        );

        if (newIpaId > 0) {
            uint256 ipaI = _createRelationship(
                LibRelationship.CreateRelationshipParams({
                    relType: ProtocolRelationships.IPA_LICENSE,
                    srcAddress: address(ipOrg_),
                    srcId: parentLicenseId,
                    srcType: 0,
                    dstAddress: address(LICENSE_REGISTRY),
                    dstId: licenseId,
                    dstType: 0
                })
            );
        } else {
            LICENSE_REGISTRY.makeTradeable(licenseId);
        }

        // If sublicense is to create work, we mint an IPA and relate it to the original IPA?
        (LibRelationship.CreateRelationshipParams memory addRel) = abi.decode(
            params_,
            (LibRelationship.CreateRelationshipParams)
        );
    */


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
        console.log("Setting ipOrg framework");
        Licensing.FrameworkConfig memory framework = abi.decode(params_, (Licensing.FrameworkConfig));
        console.log("got config");
        if (framework.nonComTermsConfig.length == 0) {
            revert Errors.LicensingModule_NonCommercialTermsRequired();
        }
        address ipOrgAddress = address(ipOrg_);
        console.log("setting commercial");
        // Set non-commercial terms
        bytes[] storage nonComTermData = _nonComIpOrgTermData[ipOrgAddress];
        EnumerableSet.Bytes32Set storage nonComTermIds = _nonComIpOrgTermIds[ipOrgAddress];
        if (nonComTermIds.length() > 0) {
            // We assume ipOrg config is immutable, licensing changes in an ipOrg imply a fork
            revert Errors.LicensingModule_IpOrgFrameworkAlreadySet();
        }
        console.log("bla");
        _setTerms(false, framework.nonComTermsConfig, nonComTermIds, nonComTermData);
        emit IpOrgTermsSet(ipOrgAddress, true, nonComTermIds.values(), nonComTermData);
        console.log("setting non commercial");
        // Set commercial terms
        bytes[] storage comTermData = _comIpOrgTermData[ipOrgAddress];
        EnumerableSet.Bytes32Set storage comTermIds = _comIpOrgTermIds[ipOrgAddress];
        _setTerms(true, framework.comTermsConfig, comTermIds, comTermData);
        emit IpOrgTermsSet(ipOrgAddress, true, comTermIds.values(), comTermData);
        
        return "";
    }

    function _setTerms(
        bool commercial,
        Licensing.TermsConfig[] memory termsConfig_,
        EnumerableSet.Bytes32Set storage termIds_,
        bytes[] storage ipOrgTermData_
    ) internal {
        // Solidity doesn't allow to store arrays of structs (TermsConfig[]) from memory to storage,
        // so we store them separately.
        // On the bright side, we can use EnumerableSet to check for termId duplicates
        uint256 termsLength = termsConfig_.length;
        console.log(termsLength);
        for (uint256 i = 0; i < termsLength; i++) {
            Licensing.TermsConfig memory config = termsConfig_[i];
            bytes32 termId = ShortString.unwrap(config.termId);
            console.log("termId");
            console.logBytes32(termId);
            if (termIds_.contains(termId)) {
                revert Errors.LicensingModule_DuplicateTermId();
            }
            Licensing.LicensingTerm memory term = getTerm(config.termId);
            console.log(address(term.hook));
            if (commercial && term.comStatus == Licensing.CommercialStatus.NonCommercial) {
                // We assume that CommercialStatus.Unset is not possible, since 
                // TermsRepository checks for that
                revert Errors.LicensingModule_InvalidTermCommercialStatus();
            }
            if (address(term.hook) != address(0)) {
                // Reverts if decoding fails
                term.hook.validateConfig(abi.encode(config));
            }
            termIds_.add(termId);
            ipOrgTermData_.push(config.data);
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
