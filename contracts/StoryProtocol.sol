// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPOrgController } from "contracts/interfaces/ip-org/IIPOrgController.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";

contract StoryProtocol {
    // TODO: should this be immutable, or should the protocol be able to change factory
    IIPOrgController public immutable FACTORY;
    ModuleRegistry public immutable MODULE_REGISTRY;

    constructor(IIPOrgController ipOrgController_, ModuleRegistry moduleRegistry_) {
        if (
            address(ipOrgController_) == address(0) ||
            address(moduleRegistry_) == address(0)
        ) {
            revert Errors.ZeroAddress();
        }
        FACTORY = ipOrgController_;
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
}
