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

import "forge-std/console.sol";

contract LicenseCreatorModule is BaseModule, TermsRepository, ProtocolTermsHelper {
    using ShortStrings for *;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    event LicensingFrameworkSet(address ipOrg_, bytes32[] termIds, bytes[] termData);

    RelationshipModule public immutable RELATIONSHIP_MODULE;
    mapping(address => bool) private _ipOrgAllowsCommercial;
    mapping(address => EnumerableSet.Bytes32Set) private _ipOrgTermIds;
    mapping(address => bytes[]) private _ipOrgTermData;

    constructor(ModuleConstruction memory params_) BaseModule(params_) {
        RELATIONSHIP_MODULE = RelationshipModule(
            address(
                MODULE_REGISTRY.moduleForKey(
                    ModuleRegistryKeys.RELATIONSHIP_MODULE
                )
            )
        );
    }

    function isIpOrgCommercial(address ipOrg_) public view returns (bool) {
        return _ipOrgAllowsCommercial[ipOrg_];
    }

    function getIpOrgTerms(address ipOrg_) public view returns (bytes32[] memory, bytes[] memory) {
        return (
            _ipOrgTermIds[ipOrg_].values(),
            _ipOrgTermData[ipOrg_]
        );
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
        
    }

    function _performAction(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) virtual internal override returns (bytes memory result) {
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
                relType: ProtocolRelationships.SUBLICENSE_REL_TYPE,
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
                    relType: ProtocolRelationships.IPA_LICENSE_REL_TYPE,
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
        

    }

    function isIpOrgLicense(uint256 licenseId_, address ipOrg_) public view returns (bool) {
        return RELATIONSHIP_MODULE.relationshipExists(
            LibRelationship.Relationship({
                relType: ProtocolRelationships.IPORG_TERMS_REL_TYPE,
                srcAddress: ipOrg_,
                srcId: 0,
                dstAddress: address(LICENSE_REGISTRY),
                dstId: licenseId_
            })
        );
    }


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
        Licensing.FrameworkConfig memory framework = abi.decode(params_, (Licensing.FrameworkConfig));
        _verifyFrameworkConfig(framework);
        // Solidity doesn't allow to store arrays of structs (TermsConfig[]) from memory to storage,
        // so we store them separately.
        // On the bright side, we can use EnumerableSet to check for duplicates
        EnumerableSet.Bytes32Set storage termIds = _ipOrgTermIds[address(ipOrg_)];
        if (termIds.length() > 0) {
            revert Errors.LicensingModule_IpOrgFrameworkAlreadySet();
        }

        _ipOrgAllowsCommercial[address(ipOrg_)] = framework.isCommercialAllowed;
        uint256 termsLength = framework.termsConfig.length;
        bytes[] storage termData = _ipOrgTermData[address(ipOrg_)];
        for (uint256 i = 0; i < termsLength; i++) {
            Licensing.TermsConfig memory config = framework.termsConfig[i];
            bytes32 termsId = ShortString.unwrap(config.termsId);
            if (termIds.contains(termsId)) {
                revert Errors.LicensingModule_DuplicateTermId();
            }
            termIds.add(termsId);
            termData.push(config.data);
        }
        emit LicensingFrameworkSet(address(ipOrg_), termIds.values(), termData);
        return "";
    }

    function _verifyFrameworkConfig(
        Licensing.FrameworkConfig memory framework_
    ) private view {
        uint256 length = framework_.termsConfig.length;
        for (uint256 i = 0; i < length; i++) {
            Licensing.TermsConfig memory config = framework_.termsConfig[i];
            Licensing.LicensingTerm memory term = getTerm(config.termsId);
            if (
                !framework_.isCommercialAllowed &&
                term.comStatus == Licensing.CommercialStatus.Commercial
            ) {
                revert Errors.LicensingModule_CommercialTermNotAllowed();
            }
            // Reverts if decoding fails
            term.hook.validateConfig(abi.encode(config));
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
