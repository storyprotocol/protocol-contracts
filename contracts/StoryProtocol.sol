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

contract StoryProtocol {
    // TODO: should this be immutable, or should the protocol be able to change factory
    IIPOrgFactory public immutable FACTORY;
    ModuleRegistry public immutable MODULE_REGISTRY;

    constructor(IIPOrgFactory ipOrgFactory_, ModuleRegistry moduleRegistry_) {
        if (address(ipOrgFactory_) == address(0) || address(moduleRegistry_) == address(0)) {
            revert Errors.ZeroAddress();
        }
        FACTORY = ipOrgFactory_;
        MODULE_REGISTRY = moduleRegistry_;
    }

    function registerIpOrg(IPOrgParams.RegisterIPOrgParams calldata params_) external returns (address) {
        return FACTORY.registerIpOrg(params_);
    }

    function addRelationshipType(LibRelationship.AddRelationshipTypeParams calldata params_) external {
        MODULE_REGISTRY.configure(
            IIPOrg(params_.ipOrg),
            msg.sender,
            ModuleRegistryKeys.RELATIONSHIP_MODULE,
            abi.encodeWithSelector(
                LibRelationship.ADD_REL_TYPE_SELECTOR,
                params_
            )
        );
    }

    function removeRelationshipType(address ipOrg_, string calldata relType) external {
        MODULE_REGISTRY.configure(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.RELATIONSHIP_MODULE,
            abi.encodeWithSelector(
                LibRelationship.REMOVE_REL_TYPE_SELECTOR,
                relType
            )
        );
    }
}