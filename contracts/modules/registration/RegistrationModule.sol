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
import { IPAsset } from "contracts/lib/IPAsset.sol";

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

    /// @notice Maps IP Orgs to their IPA configuration settings.
    mapping(address => Registration.IPOrgConfig) ipOrgConfigs;

    /// @notice Reverse lookup from IP Org asset to global IP asset ids.
    mapping(address => mapping(uint256 => uint256)) public ipAssetId;

    /// @notice IP Org asset to its tokenURI.
    mapping(address => mapping(uint256 => string)) public tokenUris;

    /// @notice Initializes the registration module.
    constructor(
        BaseModule.ModuleConstruction memory params_,
        address accessControl_
    ) BaseModule(params_) AccessControlled(accessControl_) {}


    /// @notice Registers hooks for a specific type and IP Org.
    /// @dev This function can only be called by the IP Org owner.
    /// @param hType_ The type of the hooks to register.
    /// @param ipOrg_ The IP Org for which the hooks are being registered.
    /// @param hooks_ The addresses of the hooks to register.
    /// @param hooksConfig_ The configurations for the hooks.
    function registerHooks(
        HookType hType_,
        IIPOrg ipOrg_,
        address[] calldata hooks_,
        bytes[] calldata hooksConfig_
    ) external onlyIpOrgOwner(ipOrg_) {
        bytes32 registryKey = _generateRegistryKey(ipOrg_);
        registerHooks(hType_, ipOrg_, registryKey, hooks_, hooksConfig_);
    }

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

        // If the token URI has been set to specific IP Org asset, return it.
        // It overrides the base URI.
        if (bytes(tokenUris[ipOrg_][ipOrgAssetId_]).length > 0) {
            return tokenUris[ipOrg_][ipOrgAssetId_];
        }

        Registration.IPOrgConfig memory config = ipOrgConfigs[ipOrg_];
        if (bytes(config.baseURI).length != 0) {
            return string(abi.encodePacked(config.baseURI, Strings.toString(id)));
        }

        IPAssetRegistry.IPA memory ipAsset = IPA_REGISTRY.ipAsset(id);

        // Construct the base JSON metadata with custom name format
        string memory baseJson = string(abi.encodePacked(
            '{"name": "Global IP Asset #', Strings.toString(id),
            '", "description": "IP Org Asset Registration Details", "attributes": [',
            '{"trait_type": "Name", "value": "', ipAsset.name, '"},'
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

    function getIPAssetTypes(address ipOrg_) public view returns (string[] memory) {
        return ipOrgConfigs[ipOrg_].assetTypes;
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
        (bytes32 executionType, bytes memory executionData) = abi.decode(params_, (bytes32, bytes));

         if (executionType == Registration.TRANSFER_IP_ASSET) {
            (address from, address to, uint256 id) = abi.decode(executionData, (address, address, uint256));
             if (caller_ != from || ownerOf(id) != caller_) {
                 revert Errors.RegistrationModule_InvalidCaller();
             }
        } else if (executionType == Registration.REGISTER_IP_ASSET) {
            Registration.RegisterIPAssetParams memory params = abi.decode(executionData, (Registration.RegisterIPAssetParams));
            if (params.owner != caller_) {
                revert Errors.RegistrationModule_InvalidCaller();
            }
        } else {
            revert Errors.RegistrationModule_InvalidExecutionOperation();
        }

        // TODO(leeren): Perform additional vetting on name, IP type, and CID.
    }

    /// @dev Configures the registration settings for a specific IP Org.
    /// @param ipOrg_ The IP Org being configured.
    /// @param caller_ The caller authorized to perform configuration.
    /// @param params_ Parameters passed for registration configuration.
    function _configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal returns (bytes memory) {
        _verifyConfigCaller(ipOrg_, caller_);    
        (bytes32 configType, bytes memory configData) = abi.decode(params_, (bytes32, bytes));
        if (configType == Registration.SET_IP_ORG_METADATA) {
            (string memory baseURI, string memory contractURI__) = abi.decode(configData, (string, string));
            _setMetadata(address(ipOrg_), baseURI, contractURI__);
        } else if (configType == Registration.SET_IP_ORG_ASSET_TYPES) {
            (string[] memory ipAssetTypes) = abi.decode(configData, (string[]));
            _addIPAssetTypes(address(ipOrg_), ipAssetTypes);
        } else {
            revert Errors.RegistrationModule_InvalidConfigOperation();
        }
        return "";
    }

    /// @notice Registers an IP Asset.
    /// @param params_ encoded RegisterIPAParams for module action
    /// @return encoded registry and IP Org id of the IP asset.
    function _performAction(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal returns (bytes memory) {
        (bytes32 executionType, bytes memory executionData) = abi.decode(params_, (bytes32, bytes));
        if (executionType == Registration.TRANSFER_IP_ASSET) {
            (address from, address to, uint256 id) = abi.decode(executionData, (address, address, uint256));
            _transferIPAsset(ipOrg_, id, from, to);
            return "";
        } else if (executionType == Registration.REGISTER_IP_ASSET) {
            Registration.RegisterIPAssetParams memory params = abi.decode(executionData, (Registration.RegisterIPAssetParams));
            (uint256 ipAssetId__, uint256 ipOrgAssetId) = _registerIPAsset(ipOrg_, params.owner, params.name, params.ipAssetType, params.hash, params.mediaUrl);
            return abi.encode(ipAssetId__, ipOrgAssetId);
        }
        return "";
    }

    /// @dev Registers a new IP asset and wraps it under the provided IP Org.
    /// @param ipOrg_ The governing entity of the IP asset being registered.
    /// @param owner_ The initial registrant and owner of the IP asset.
    /// @param name_ A descriptive name for the IP asset being registered.
    /// @param ipAssetType_ A numerical identifier for the IP asset type.
    /// @param hash_ The content hash of the IP asset being registered.
    /// @param mediaUrl_ The media URL of the IP asset being registered.
    function _registerIPAsset(
        IIPOrg ipOrg_,
        address owner_,
        string memory name_,
        uint64 ipAssetType_,
        bytes32 hash_,
        string memory mediaUrl_
    ) internal returns (uint256 ipAssetId_, uint256 ipOrgAssetId_) {
        ipAssetId_ = IPA_REGISTRY.register(
            address(ipOrg_),
            owner_,
            name_,
            ipAssetType_,
            hash_
        );
        ipOrgAssetId_ = ipOrg_.mint(owner_);
        ipAssetId[address(ipOrg_)][ipOrgAssetId_] = ipAssetId_;
        IPOrgAsset memory ipOrgAsset = IPOrgAsset(address(ipOrg_), ipOrgAssetId_);
        ipOrgAssets[ipAssetId_] = ipOrgAsset;
        if (bytes(mediaUrl_).length > 0) {
            tokenUris[address(ipOrg_)][ipOrgAssetId_] = mediaUrl_;
        }
        emit IPAssetRegistered(
            ipAssetId_,
            address(ipOrg_),
            ipOrgAssetId_,
            owner_,
            name_,
            ipAssetType_,
            hash_,
            mediaUrl_
        );
    }

    /// @dev Transfers ownership of an IP asset to a new owner.
    /// @param ipOrg_ The address of the currently governing IP Org.
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

    /// @dev Transfers an IP asset to a new governing IP Org.
    /// @param fromIpOrg_ The address of the original governing IP Org.
    /// @param fromIpOrgAssetId_ The existing id of the IP asset within the IP Org.
    /// @param toIpOrg_ The address of the new governing IP Org.
    /// TODO(leeren) Expose this function to FE once IP Orgs are finalized.
    function _transferIPAssetToIPOrg(
        address fromIpOrg_,
        uint256 fromIpOrgAssetId_,
        address toIpOrg_,
        address from_,
        address to_
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


    /// @dev Adds new IP asset types to an IP Org.
    /// @param ipOrg_ The address of the IP Org whose asset types we are adding.
    /// @param ipAssetTypes_ String descriptors of the asset types being added.
    /// TODO: Add ability to deprecate asset types.
    function _addIPAssetTypes(
        address ipOrg_,
        string[] memory ipAssetTypes_
    ) internal {
        Registration.IPOrgConfig storage ipOrg = ipOrgConfigs[ipOrg_];
        for (uint i = 0; i < ipAssetTypes_.length; i++) {
            ipOrg.assetTypes.push(ipAssetTypes_[i]);
        }
    }

    /// @dev Sets the IPOrg token and contract metadata.
    /// @param ipOrg_ The address of the IP Org whose metadata is changing.
    /// @param baseURI_ The new base URI to assign for the IP Org.
    /// @param contractURI_ The new base contract URI to assign for the IP Org.
    function _setMetadata(
        address ipOrg_,
        string memory baseURI_,
        string memory contractURI_
    ) internal {
        Registration.IPOrgConfig storage config =  ipOrgConfigs[ipOrg_];
        config.baseURI = baseURI_;
        config.contractURI = contractURI_;
        emit MetadataUpdated(ipOrg_, baseURI_, contractURI_);
    }

    /// @dev Verifies the caller of a configuration action.
    /// TODO(leeren): Deprecate in favor of policy-based function auth.
    function _verifyConfigCaller(IIPOrg ipOrg_, address caller_) private view {
        if (ipOrg_.owner() != caller_ && address(IP_ORG_CONTROLLER) != caller_) {
            revert Errors.Unauthorized();
        }
    }

    function _hookRegistryKey(
        IIPOrg ipOrg_,
        address,
        bytes calldata
    ) internal view virtual override returns(bytes32) {
        return _generateRegistryKey(ipOrg_);
    }

    function _generateRegistryKey(IIPOrg ipOrg_) private pure returns(bytes32) {
        return keccak256(abi.encode(address(ipOrg_), "REGISTRATION"));
    }
}
