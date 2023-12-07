// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
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
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { FixedSet } from "contracts/utils/FixedSet.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";

/// @title Story Protocol Gateway Contract
/// @notice The Story Protocol contract acts as a global gateway for calling all
///         protocol-standardized IP actions (based on their enrolled modules).
///         Most functions can be solely executed through this contract, as it will
///         be actively maintained and upgraded to support all standardized modules.
///         In the future, for more customized logic, IP Orgs may choose to create 
///         their own frontend contracts (gateways) for IP interaction.
contract StoryProtocol is Multicall {

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

    /// @notice Adds additional IP asset types for an IP Org.
    /// @param ipOrg_ The address of the IP Org being configured.
    /// @param ipAssetTypes_ The new IP asset type descriptors to add.
    function addIPAssetTypes(
        address ipOrg_,
        string[] calldata ipAssetTypes_
    ) public {
        bytes memory encodedParams = abi.encode(
            Registration.SET_IP_ORG_ASSET_TYPES,
            abi.encode(ipAssetTypes_)
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
        string calldata symbol_,
        string[] calldata ipAssetTypes_
    ) external returns (address ipOrg_) {
        return IP_ORG_CONTROLLER.registerIpOrg(
            owner_,
            name_,
            symbol_,
            ipAssetTypes_
        );
    }

    /// @notice Registers an IP Asset.
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
        bytes memory encodedParams = abi.encode(Registration.REGISTER_IP_ASSET, abi.encode(params_));
        bytes memory result = MODULE_REGISTRY.execute(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.REGISTRATION_MODULE,
            encodedParams,
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
        MODULE_REGISTRY.execute(
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

    ////////////////////////////////////////////////////////////////////////////
    //                            Licensing                                   //
    ////////////////////////////////////////////////////////////////////////////

    /// Allows an IPOrg to configure its licensing framework (collection of commercial and non-commercial terms)
    /// @param ipOrg_ the ipOrg address
    /// @param config_ the licensing framework config
    function configureIpOrgLicensing(
        address ipOrg_,
        Licensing.LicensingConfig calldata config_
    ) external {
        MODULE_REGISTRY.configure(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.LICENSING_MODULE,
            abi.encode(Licensing.LICENSING_FRAMEWORK_CONFIG, abi.encode(config_))
        );
    }
    
    /// Creates a tradeable License NFT in License Registry.
    /// @param ipOrg_ the ipOrg address
    /// @param params_ LicenseCreation params
    /// @param preHooksData_ Hooks data to embed with the registration pre-call.
    /// @param postHooksData_ Hooks data to embed with the registration post-call.
    /// @return id of the created license
    function createLicense(
        address ipOrg_,
        Licensing.LicenseCreation calldata params_,
        bytes[] calldata preHooksData_,
        bytes[] calldata postHooksData_
    ) external returns (uint256) {
        bytes memory params = abi.encode(params_);
        bytes memory result = MODULE_REGISTRY.execute(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.LICENSING_MODULE,
            abi.encode(
                Licensing.CREATE_LICENSE,
                params
            ),
            preHooksData_,
            postHooksData_
        );
        return abi.decode(result, (uint256));
    }

    /// Activates a license that's Pending Approval
    /// @param ipOrg_ the ipOrg address
    /// @param licenseId_ the license id
    function activateLicense(
        address ipOrg_,
        uint256 licenseId_
    ) external {
        MODULE_REGISTRY.execute(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.LICENSING_MODULE,
            abi.encode(
                Licensing.ACTIVATE_LICENSE,
                abi.encode(licenseId_)
            ),
            new bytes[](0),
            new bytes[](0)
        );
    }

    /// Associates a license with an IPA
    /// @param ipOrg_ the ipOrg address
    /// @param licenseId_ the license id
    /// @param ipaId_ the ipa id
    function linkLnftToIpa(
        address ipOrg_,
        uint256 licenseId_,
        uint256 ipaId_
    ) external {
        MODULE_REGISTRY.execute(
            IIPOrg(ipOrg_),
            msg.sender,
            ModuleRegistryKeys.LICENSING_MODULE,
            abi.encode(
                Licensing.LINK_LNFT_TO_IPA,
                abi.encode(licenseId_, ipaId_)
            ),
            new bytes[](0),
            new bytes[](0)
        );
    }
}
