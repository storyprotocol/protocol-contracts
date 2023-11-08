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

contract LicensingModule is BaseModule {

    RelationshipModule public immutable RELATIONSHIP_MODULE;

    constructor(ModuleConstruction memory params_) BaseModule(params_) {
        RELATIONSHIP_MODULE = RelationshipModule(
            address(
                MODULE_REGISTRY.moduleForKey(
                    ModuleRegistryKeys.RELATIONSHIP_MODULE
                )
            )
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

    function _configure(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) virtual override internal returns (bytes memory) {
        (bytes32 configType, bytes memory configData) = abi.decode(params_, (bytes32, bytes));
        if (configType == Licensing.IPORG_TERMS_CONFIG) {
            return _setIpOrgLicensingTerms(ipOrg_, caller_, configData);
        } else {
            // TODO: check if caller is License holder and can modify something from his license?
        }
        revert Errors.LicensingModule_InvalidConfigType();
    }

    function _setIpOrgLicensingTerms(
        IIPOrg ipOrg_,
        address caller_,
        bytes memory params_
    ) virtual internal returns (bytes memory) {
        if (ipOrg_.owner() != caller_) {
            revert Errors.LicensingModule_CallerNotIPOrgOwner();
        }
        Licensing.License memory license = abi.decode(params_, (Licensing.License));
        uint256 licenseId = LICENSE_REGISTRY.addLicense(license);
        LibRelationship.CreateRelationshipParams memory addRelParams = LibRelationship.CreateRelationshipParams({
            relType: ProtocolRelationships.IPORG_TERMS_REL_TYPE,
            srcAddress: address(ipOrg_),
            srcId: 0,
            srcType: 0,
            dstAddress: address(LICENSE_REGISTRY),
            dstId: licenseId,
            dstType: 0
        });
        uint256 relId = abi.decode(
            MODULE_REGISTRY.execute(
                ipOrg_,
                ModuleRegistryKeys.RELATIONSHIP_MODULE,
                abi.encode(addRelParams),
                new bytes[](0),
                new bytes[](0)
            ),
            (uint256)
        );
        return abi.encode(licenseId, relId);
    }

}
