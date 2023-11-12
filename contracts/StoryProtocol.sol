// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPOrgFactory } from "contracts/interfaces/ip-org/IIPOrgFactory.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";

contract StoryProtocol {
    // TODO: should this be immutable, or should the protocol be able to change factory
    IIPOrgFactory public immutable FACTORY;
    ModuleRegistry public immutable MODULE_REGISTRY;

    constructor(IIPOrgFactory ipOrgFactory_, ModuleRegistry moduleRegistry_) {
        if (
            address(ipOrgFactory_) == address(0) ||
            address(moduleRegistry_) == address(0)
        ) {
            revert Errors.ZeroAddress();
        }
        FACTORY = ipOrgFactory_;
        MODULE_REGISTRY = moduleRegistry_;
    }

    function registerIpOrg(
        IPOrgParams.RegisterIPOrgParams calldata params_
    ) external returns (address) {
        return FACTORY.registerIpOrg(params_);
    }

    ////////////////////////////////////////////////////////////////////////////
    //                            Relationships                               //
    ////////////////////////////////////////////////////////////////////////////

    function addRelationshipType(
        LibRelationship.AddRelationshipTypeParams calldata params_
    ) external {
        MODULE_REGISTRY.configure(
            IIPOrg(params_.ipOrg),
            msg.sender,
            ModuleRegistryKeys.RELATIONSHIP_MODULE,
            abi.encode(LibRelationship.ADD_REL_TYPE_CONFIG, abi.encode(params_))
        );
    }

    function removeRelationshipType(
        address ipOrg_,
        string calldata relType
    ) external {
        MODULE_REGISTRY.configure(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.RELATIONSHIP_MODULE,
            abi.encode(
                LibRelationship.REMOVE_REL_TYPE_CONFIG,
                abi.encode(relType)
            )
        );
    }

    function createRelationship(
        address ipOrg_,
        LibRelationship.CreateRelationshipParams calldata params_,
        bytes[] calldata preHooksData_,
        bytes[] calldata postHooksData_
    ) external returns(uint256 relId) {
        bytes memory result = MODULE_REGISTRY.execute(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.RELATIONSHIP_MODULE,
            abi.encode(params_),
            preHooksData_,
            postHooksData_
        );
        return abi.decode(result, (uint256));
    }

    ////////////////////////////////////////////////////////////////////////////
    //                            Licensing                                   //
    ////////////////////////////////////////////////////////////////////////////


    function configureIpOrgLicensing(
        address ipOrg_,
        Licensing.FrameworkConfig calldata framework_
    ) external {
        MODULE_REGISTRY.configure(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.LICENSING_MODULE,
            abi.encode(Licensing.LICENSING_FRAMEWORK_CONFIG, abi.encode(framework_))
        );
    }

    // Create a sublicense for an existing IPA (or license?)
    // This can be:
    // To make merch (tradeable, no IPA as result)
    // To adapt/remix/extend (tradeable, IPA will be result)
    // This method will set Activation terms (approvals, kyc, etc)
    // How do we allow marketplaces for permissionless license?
    // How can we differentiate a request for license, from a license?
    // Something has to check that you have licenses for all the related characters to give you commercial rights (terms to check for a set of relationships)
    // IpOrgs can set hooks on creation (token gating, etc), for commercial or non commercial
    function createLicense(
        address ipOrg_,
        Licensing.LicenseCreationParams calldata params_,
        bytes[] calldata preHooksData_,
        bytes[] calldata postHooksData_
    ) external returns (uint256) {
        return abi.decode(
            MODULE_REGISTRY.execute(
                IIPOrg(ipOrg_),
                msg.sender,
                ModuleRegistryKeys.LICENSING_MODULE,
                abi.encode(params_),
                preHooksData_,
                postHooksData_
            ),
            (uint256)
        );
    }



}