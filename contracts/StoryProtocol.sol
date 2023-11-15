// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPOrgController } from "contracts/interfaces/ip-org/IIPOrgController.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { Registration } from "contracts/lib/modules/Registration.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";

contract StoryProtocol {

    IIPOrgController public immutable IP_ORG_CONTROLLER;
    ModuleRegistry public immutable MODULE_REGISTRY;

    constructor(IIPOrgController ipOrgController_, ModuleRegistry moduleRegistry_) {
        if (
            address(ipOrgController_) == address(0) ||
            address(moduleRegistry_) == address(0)
        ) {
            revert Errors.ZeroAddress();
        }
        IP_ORG_CONTROLLER = ipOrgController_;
        MODULE_REGISTRY = moduleRegistry_;
    }

    ////////////////////////////////////////////////////////////////////////////
    //                                 IPOrg                                  //
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Sets the metadata for an IP Org.
    /// @param ipOrg_ The address of the IP Org being configured.
    /// @param baseURI_ The base token metadata URI for the IP Org.
    /// @param contractURI_ The contract URI associated with the IP Org.
    function setMetadata(
        address ipOrg_,
        string calldata baseURI_,
        string calldata contractURI_
    ) public {
        bytes memory encodedParams = abi.encode(
            Registration.SET_IP_ORG_METADATA,
            abi.encode(baseURI_, contractURI_)
        );
        MODULE_REGISTRY.configure(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.REGISTRATION_MODULE,
            encodedParams
        );
    }

    /// @notice Registers a new IP Org
    /// @param owner_ The address of the IP Org to be registered.
    /// @param name_ A name to associate with the IP Org.
    /// @param symbol_ A symbol to associate with the IP Org.
    /// TODO: Add module configurations to the IP Org registration process.
    /// TODO: Add permissions for IP Org registration.
    function registerIpOrg(
        address owner_,
        string calldata name_,
        string calldata symbol_
    ) external returns (address ipOrg_) {
        return IP_ORG_CONTROLLER.registerIpOrg(
            owner_,
            name_,
            symbol_
        );
    }

    /// @notice Transfers an IP asset to another owner.
    /// @param ipOrg_ The governing IP Org under which the IP asset is registered.
    /// @param params_ The registration params, including owner, name, hash.
    /// @param preHooksData_ Hooks to embed with the registration pre-call.
    /// @param postHooksData_ Hooks to embed with the registration post-call.
    /// @return The global IP asset and local IP Org asset id.
    function registerIPAsset(
        address ipOrg_,
        Registration.RegisterIPAssetParams calldata params_,
        bytes[] calldata preHooksData_,
        bytes[] calldata postHooksData_
    ) public returns (uint256, uint256) {
        bytes memory encodedParams = abi.encode(
            Registration.REGISTER_IP_ASSET,
            abi.encode(params_)
        );
        bytes memory result = MODULE_REGISTRY.execute(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.REGISTRATION_MODULE,
            abi.encode(params_),
            preHooksData_,
            postHooksData_
        );
        return abi.decode(result, (uint256, uint256));
    }

    /// @notice Transfers an IP asset to another owner.
    /// @param ipOrg_ The IP Org which the IP asset is associated with.
    /// @param from_ The address of the current owner of the IP asset.
    /// @param to_ The address of the new owner of the IP asset.
    /// @param ipAssetId_ The global id of the IP asset being transferred.
    function transferIPAsset(
        address ipOrg_,
        address from_,
        address to_,
        uint256 ipAssetId_,
        bytes[] calldata preHooksData_,
        bytes[] calldata postHooksData_
    ) public {
        bytes memory encodedParams = abi.encode(
            Registration.TRANSFER_IP_ASSET,
            abi.encode(from_, to_, ipAssetId_)
        );
        bytes memory result = MODULE_REGISTRY.execute(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.REGISTRATION_MODULE,
            encodedParams,
            preHooksData_,
            postHooksData_
        );
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
