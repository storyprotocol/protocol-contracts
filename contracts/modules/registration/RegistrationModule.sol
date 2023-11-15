// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { IRegistrationModule } from "contracts/interfaces/modules/registration/IRegistrationModule.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { Registration } from "contracts/lib/modules/Registration.sol";
import { LibUintArrayMask } from "contracts/lib/LibUintArrayMask.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Registration Module
/// @notice Handles registration and transferring of IP assets..
contract RegistrationModule is BaseModule, IRegistrationModule, AccessControlled {

    using Strings for uint256;

    /// @notice Representation of a wrapped IP asset within an IP Org.
    struct IPOrgAsset {
        address ipOrg;
        uint256 ipOrgAssetId;
    }

    /// @notice Maps global IP asset Ids to IP Org wrapped assets.
    mapping(uint256 => IPOrgAsset) ipOrgAssets;

    /// @notice Reverse mapping of IP Orgs to their IPA configuration settings.
    mapping(address => Registration.IPOrgConfig) ipOrgConfigs;

    /// @notice Reverse lookup from IP Org asset to GIPR asset ids.
    mapping(address => mapping(uint256 => uint256)) public ipAssetId;

    /// @notice Initializes the registration module.
    constructor(
        BaseModule.ModuleConstruction memory params_,
        address accessControl_
    ) BaseModule(params_) AccessControlled(accessControl_) {}

    /// @notice Gets the contract URI for an IP Org.
    /// @param ipOrg_ The address of the IP Org.
    function contractURI(address ipOrg_) public view returns (string memory) {
        string memory uri = ipOrgConfigs[ipOrg_].contractURI;
        if (bytes(uri).length == 0) {
            revert Errors.RegistrationModule_IPOrgNotConfigured();
        }
        return uri;
    }

    /// @notice Renders metadata of an IP Asset localized for an IP Org.
    /// @param ipOrg_ The address of the IP Org of the IP asset.
    /// @param ipOrgAssetId_ The local id of the IP asset within the IP Org.
    function tokenURI(address ipOrg_, uint256 ipOrgAssetId_) public view returns (string memory) {
        uint256 id = ipAssetId[ipOrg_][ipOrgAssetId_];
        address owner = IIPOrg(ipOrg_).ownerOf(ipOrgAssetId_);
        if (owner == address(0)) {
            revert Errors.RegistrationModule_IPAssetNonExistent();
        }

        Registration.IPOrgConfig memory config = ipOrgConfigs[ipOrg_];
        if (bytes(config.baseURI).length != 0) {
            return string(abi.encodePacked(config.baseURI, Strings.toString(id)));
        }

        IPAssetRegistry.IPA memory ipAsset = IPA_REGISTRY.ipAsset(id);

        // Construct the base JSON metadata with custom name format
        string memory baseJson = string(abi.encodePacked(
            '{"name": "Global IP Asset #', Strings.toString(id),
            ': ', ipAsset.name,
            '", "description": "IP Org Asset Registration Details", "attributes": ['
        ));


        string memory ipOrgAttributes = string(abi.encodePacked(
            '{"trait_type": "IP Org", "value": "', Strings.toHexString(uint160(ipAsset.ipOrg), 20), '"},',
            '{"trait_type": "Current IP Owner", "value": "', Strings.toHexString(uint160(owner), 20), '"},'
        ));

        string memory ipAssetAttributes = string(abi.encodePacked(
            '{"trait_type": "Initial Registrant", "value": "', Strings.toHexString(uint160(ipAsset.registrant), 20), '"},',
            '{"trait_type": "IP Asset Type", "value": "', Strings.toString(ipAsset.ipAssetType), '"},',
            '{"trait_type": "Status", "value": "', Strings.toString(ipAsset.status), '"},',
            '{"trait_type": "Hash", "value": "', Strings.toHexString(uint256(ipAsset.hash), 32), '"},',
            '{"trait_type": "Registration Date", "value": "', Strings.toString(ipAsset.registrationDate), '"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string(abi.encodePacked(
                        baseJson,
                        ipOrgAttributes,
                        ipAssetAttributes,
                        ']}'
                    )
                )
            ))
        ));
    }

    /// @notice Gets the current owner of an IP asset.
    /// @param ipAssetId_ The global IP asset id being queried.
    function ownerOf(uint256 ipAssetId_) public view returns (address) {
        IPOrgAsset memory ipOrgAsset = ipOrgAssets[ipAssetId_];
        return IIPOrg(ipOrgAsset.ipOrg).ownerOf(ipOrgAsset.ipOrgAssetId);
    }

    /// Verifies that the relationship execute() wants to set is valid according to its type definition
    /// @param ipOrg_ IPOrg address or zero address for protocol level relationships
    /// @param params_ encoded params for module action
    function _verifyExecution(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal {
        Registration.RegisterIPAParams memory params = abi.decode(params_, (Registration.RegisterIPAParams));

        if (params.owner != caller_) {
            revert Errors.RegistrationModule_InvalidCaller();
        }

        // TODO(leeren): Perform additional vetting on name, IP type, and CID.
    }

    /// @dev Configures the registration settings for a specific IP Org.
    /// @param ipOrg_ The IP Org being configured.
    /// @param caller_ The caller authorized to perform configuration.
    /// @param params_ Parameters passed for registration configuration.
    function _configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal {
        if (ipOrg_.owner() != caller_) {
            revert Errors.RegistrationModule_CallerNotAuthorized();
        }
        Registration.IPOrgConfig memory config = abi.decode(params_, (Registration.IPOrgConfig));
    }

    /// @notice Registers an IP Asset.
    /// @param params_ encoded RegisterIPAParams for module action
    /// @return encoded registry and IP Org id of the IP asset.
    function _performAction(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal returns (bytes memory) {
        Registration.RegisterIPAParams memory params = abi.decode(params_, (Registration.RegisterIPAParams));
        (uint256 globalIpAssetId, uint256 localIpAssetId) = _registerIPAsset(
            ipOrg_,
            params.owner,
            params.name,
            params.ipAssetType,
            params.hash
        );
        return abi.encode(globalIpAssetId, localIpAssetId);
    }

    /// @dev Registers a new IP asset and wraps it under the provided IP Org.
    /// @param ipOrg_ The governing entity of the IP asset being registered.
    /// @param owner_ The initial registrant and owner of the IP asset.
    /// @param name_ A descriptive name for the IP asset being registered.
    /// @param ipAssetType_ A numerical identifier for the IP asset type.
    /// @param hash_ The content hash of the IP asset being registered.
    function _registerIPAsset(
        IIPOrg ipOrg_,
        address owner_,
        string memory name_,
        uint64 ipAssetType_,
        bytes32 hash_
    ) internal returns (uint256 ipAssetId_, uint256 ipOrgAssetId_) {
        ipAssetId_ = IPA_REGISTRY.register(
            owner_,
            name_,
            ipAssetType_,
            hash_
        );
        ipOrgAssetId_ = ipOrg_.mint(owner_);
        ipAssetId[address(ipOrg_)][ipOrgAssetId_] = ipAssetId_;
        IPOrgAsset memory ipOrgAsset = IPOrgAsset(address(ipOrg_), ipOrgAssetId_);
        ipOrgAssets[ipAssetId_] = ipOrgAsset;
        emit IPAssetRegistered(
            ipAssetId_,
            address(ipOrg_),
            ipOrgAssetId_,
            owner_,
            name_,
            ipAssetType_,
            hash_
        );
    }

    /// @dev Transfers an IP asset to a new governing IP Org.
    /// @param fromIpOrg_ The address of the original governing IP Org.
    /// @param fromIpOrgAssetId_ The existing id of the IP asset within the IP Org.
    /// @param toIpOrg_ The address of the new governing IP Org.
    function _transferIPOrg(
        address fromIpOrg_,
        uint256 fromIpOrgAssetId_,
        address toIpOrg_
    ) internal returns (uint256 ipAssetId_, uint256 ipOrgAssetId_) {
        uint256 id = ipAssetId[address(fromIpOrg_)][fromIpOrgAssetId_];

        address owner = IIPOrg(fromIpOrg_).ownerOf(ipOrgAssetId_);

        delete ipAssetId[address(fromIpOrg_)][fromIpOrgAssetId_];
        delete ipOrgAssets[id];
        IIPOrg(fromIpOrg_).burn(ipOrgAssetId_);
        IPA_REGISTRY.transferIPOrg(
            ipAssetId_,
            toIpOrg_
        );
        ipOrgAssetId_ = IIPOrg(toIpOrg_).mint(owner);
        IPOrgAsset memory ipOrgAsset = IPOrgAsset(toIpOrg_, ipOrgAssetId_);
        ipOrgAssets[id] = ipOrgAsset;
        ipAssetId[address(toIpOrg_)][ipOrgAssetId_] = id;
    }

    /// @dev Transfers ownership of an IP asset to a new owner.
    /// @param ipOrg_ The address of the governing IP Org.
    /// @param ipOrgAssetId_ The local id of the IP asset within the IP Org.
    /// @param from_ The current owner of the IP asset within the IP Org.
    /// @param to_ The new owner of the IP asset within the IP Org.
    function _transferIPAsset(
        IIPOrg ipOrg_,
        uint256 ipOrgAssetId_,
        address from_,
        address to_
    ) internal {
        ipOrg_.transferFrom(from_, to_, ipOrgAssetId_);
        uint256 id = ipAssetId[address(ipOrg_)][ipOrgAssetId_];
        emit IPAssetTransferred(
            id,
            address(ipOrg_),
            ipOrgAssetId_,
            from_,
            to_
        );
    }

    /// @dev Returns the administrator for the registration module hooks.
    /// TODO(kingter) Define the administrator for this call.
    function _hookRegistryAdmin()
        internal
        view
        virtual
        override
        returns (address)
    {
        return address(0);
    }

}
