// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { IRegistrationModule } from "contracts/interfaces/modules/registration/IRegistrationModule.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { IModule } from "contracts/interfaces/modules/base/IModule.sol";
import { Registration } from "contracts/lib/modules/Registration.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ModuleKey, REGISTRATION_MODULE_KEY } from "contracts/lib/modules/Module.sol";

/// @title Registration Module
/// @notice The registration module is responsible for registration, transferring, and
///         metadata management of IP assets. During registration, this module will
///         register an IP asset in the global IP asset registry, and then wraps
///         it as a localized IP asset NFT under its governing IP Org.
contract RegistrationModule is BaseModule, IRegistrationModule, AccessControlled {
    using Strings for uint256;

    /// @notice Representation of a wrapped IP asset within an IP Org.
    struct IPOrgAsset {
        address ipOrg; // The address of the governing IP Org.
        uint256 ipOrgAssetId; // The localized if of the IP asset within the IP Org.
    }

    /// @notice Maps global IP asset ids to IP Org wrapped assets.
    mapping(uint256 => IPOrgAsset) public ipOrgAssets;

    /// @notice Maps IP Orgs to their IPA configuration settings.
    mapping(address => Registration.IPOrgConfig) public ipOrgConfigs;

    /// @notice Reverse lookup from IP Org asset to global IP asset ids.
    mapping(address => mapping(uint256 => uint256)) public ipAssetId;

    /// @notice Maps IP Org assets to their token URIs.
    mapping(address => mapping(uint256 => string)) public tokenUris;

    /// @notice Maximum number of Ip Org asset types.
    uint256 public constant MAX_IP_ORG_ASSET_TYPES = type(uint8).max;

    /// @notice Initializes the registration module.
    /// @param params_ Params necessary for all protocol-wide modules.
    /// @param accessControl_ Global access control singleton used for protocol authorization.
    constructor(
        BaseModule.ModuleConstruction memory params_,
        address accessControl_
    ) BaseModule(params_) AccessControlled(accessControl_) {}

    /// @notice Gets the protocol-wide module key for the registration module.
    /// @return The module key used for identifying the registration module.
    function moduleKey() public pure override(BaseModule, IModule) returns (ModuleKey) {
        return REGISTRATION_MODULE_KEY;
    }

    /// @notice Registers hooks for a specific type and IP Org.
    /// @dev This function can only be called by the IP Org owner.
    /// @param hType_ The type of the hooks to register.
    /// @param ipOrg_ The IP Org for which the hooks are being registered.
    /// @param hooks_ The addresses of the hooks to register.
    /// @param hooksConfig_ The configurations for the hooks.
    /// @param registerParams_ The parameters for the registration.
    function registerHooks(
        HookType hType_,
        IIPOrg ipOrg_,
        address[] calldata hooks_,
        bytes[] calldata hooksConfig_,
        bytes calldata registerParams_
    ) external onlyIpOrgOwner(ipOrg_) {
        bytes32 executionType_ = abi.decode(registerParams_, (bytes32));
        bytes32 registryKey = _generateRegistryKey(ipOrg_, executionType_);
        registerHooks(hType_, ipOrg_, registryKey, hooks_, hooksConfig_);
    }

    /// @notice Gets the contract URI for an IP Org.
    /// @param ipOrg_ The address of the IP Org.
    /// @return The contract URI identifying an IP Org contract.
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
    /// @param ipOrgAssetType_ The IP Org asset type.
    /// @return The token URI associated with a specific IP Org localized IP asset.
    function tokenURI(
        address ipOrg_,
        uint256 ipOrgAssetId_,
        uint8 ipOrgAssetType_
    ) public view returns (string memory) {
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
        string memory baseJson = string(
            /* solhint-disable */
            abi.encodePacked(
                '{"name": "Global IP Asset #',
                Strings.toString(id),
                '", "description": "IP Org Asset Registration Details", "attributes": [',
                '{"trait_type": "Name", "value": "',
                ipAsset.name,
                '"},'
            )
            /* solhint-enable */
        );

        string memory ipOrgAttributes = string(
            /* solhint-disable */
            abi.encodePacked(
                '{"trait_type": "IP Org", "value": "',
                Strings.toHexString(uint160(ipAsset.ipOrg), 20),
                '"},',
                '{"trait_type": "Current IP Owner", "value": "',
                Strings.toHexString(uint160(owner), 20),
                '"},'
            )
            /* solhint-enable */
        );

        string memory ipAssetAttributes = string(
            /* solhint-disable */
            abi.encodePacked(
                '{"trait_type": "Initial Registrant", "value": "',
                Strings.toHexString(uint160(ipAsset.registrant), 20),
                '"},',
                '{"trait_type": "IP Org Asset Type", "value": "',
                config.assetTypes[ipOrgAssetType_],
                '"},',
                '{"trait_type": "Status", "value": "',
                Strings.toString(ipAsset.status),
                '"},',
                '{"trait_type": "Hash", "value": "',
                Strings.toHexString(uint256(ipAsset.hash), 32),
                '"},',
                '{"trait_type": "Registration Date", "value": "',
                Strings.toString(ipAsset.registrationDate),
                '"}'
            )
            /* solhint-enable */
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(string(abi.encodePacked(baseJson, ipOrgAttributes, ipAssetAttributes, "]}"))))
                )
            );
    }

    /// @notice Gets the asset types of an IP Org.
    /// @param ipOrg_ Address of the IP Org whose asset types are being queried for.
    function getIpOrgAssetTypes(address ipOrg_) public view returns (string[] memory) {
        return ipOrgConfigs[ipOrg_].assetTypes;
    }

    /// @notice Checks whether an IP Org asset type is supported.
    /// @param ipOrg_ Address of the IP Org to which the IP asset type belongs.
    /// @param assetTypeIndex_ The index representing the targeted IP asset type.
    function isValidIpOrgAssetType(address ipOrg_, uint8 assetTypeIndex_) public view returns (bool) {
        return assetTypeIndex_ < ipOrgConfigs[ipOrg_].assetTypes.length;
    }

    /// @notice Gets the current owner of an IP asset.
    /// @param ipAssetId_ The global IP asset id being queried.
    /// @return The address of the owner of the IP asset.
    function ownerOf(uint256 ipAssetId_) public view returns (address) {
        IPOrgAsset memory ipOrgAsset = ipOrgAssets[ipAssetId_];
        return IIPOrg(ipOrgAsset.ipOrg).ownerOf(ipOrgAsset.ipOrgAssetId);
    }

    /// @dev Verifies if execution of an IP asset registration or transfer is successful.
    /// @param ipOrg_ Address of the relevant IP Org (used only for registration).
    /// @param params_ Encoded params used for registration processing (see Registration module).
    function _verifyExecution(IIPOrg ipOrg_, address caller_, bytes calldata params_) internal virtual override {
        (bytes32 executionType, bytes memory executionData) = abi.decode(params_, (bytes32, bytes));

        if (executionType == Registration.TRANSFER_IP_ASSET) {
            (address from, , uint256 id) = abi.decode(executionData, (address, address, uint256));
            if (caller_ != from || ownerOf(id) != caller_) {
                revert Errors.RegistrationModule_InvalidCaller();
            }
        } else if (executionType == Registration.REGISTER_IP_ASSET) {
            Registration.RegisterIPAssetParams memory params = abi.decode(
                executionData,
                (Registration.RegisterIPAssetParams)
            );
            if (params.owner != caller_) {
                revert Errors.RegistrationModule_InvalidCaller();
            }
            _verifyIpOrgAssetType(address(ipOrg_), params.ipOrgAssetType);
        } else {
            revert Errors.RegistrationModule_InvalidExecutionOperation();
        }
    }

    /// @dev Configures the registration settings for a specific IP Org.
    /// @param ipOrg_ The IP Org being configured.
    /// @param caller_ The caller authorized to perform configuration.
    /// @param params_ Parameters passed for registration configuration.
    function _configure(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata params_
    ) internal virtual override returns (bytes memory) {
        _verifyConfigCaller(ipOrg_, caller_);
        (bytes32 configType, bytes memory configData) = abi.decode(params_, (bytes32, bytes));
        if (configType == Registration.SET_IP_ORG_METADATA) {
            (string memory baseURI, string memory contractUri) = abi.decode(configData, (string, string));
            _setMetadata(address(ipOrg_), baseURI, contractUri);
        } else if (configType == Registration.SET_IP_ORG_ASSET_TYPES) {
            string[] memory ipAssetTypes = abi.decode(configData, (string[]));
            _addIPAssetTypes(address(ipOrg_), ipAssetTypes);
        } else {
            revert Errors.RegistrationModule_InvalidConfigOperation();
        }
        return "";
    }

    /// @notice Registers an IP Asset.
    /// @param params_ encoded RegisterIPAParams for module action
    /// @return Encoded registry and IP Org id of the IP asset.
    function _performAction(
        IIPOrg ipOrg_,
        address,
        bytes memory params_
    ) internal virtual override returns (bytes memory) {
        (bytes32 executionType, bytes memory executionData) = abi.decode(params_, (bytes32, bytes));
        if (executionType == Registration.TRANSFER_IP_ASSET) {
            (address from, address to, uint256 id) = abi.decode(executionData, (address, address, uint256));
            _transferIPAsset(ipOrg_, id, from, to);
            return "";
        } else if (executionType == Registration.REGISTER_IP_ASSET) {
            Registration.RegisterIPAssetParams memory params = abi.decode(
                executionData,
                (Registration.RegisterIPAssetParams)
            );
            (uint256 ipAsset, uint256 ipOrgAssetId) = _registerIPAsset(
                ipOrg_,
                params.owner,
                params.name,
                params.ipOrgAssetType,
                params.hash,
                params.mediaUrl
            );
            return abi.encode(ipAsset, ipOrgAssetId);
        }
        return "";
    }

    /// @dev Registers a new IP asset and wraps it under the provided IP Org.
    /// @param ipOrg_ The governing entity of the IP asset being registered.
    /// @param owner_ The initial registrant and owner of the IP asset.
    /// @param name_ A descriptive name for the IP asset being registered.
    /// @param ipOrgAssetType_ A numerical identifier for the IP asset type.
    /// @param hash_ The content hash of the IP asset being registered.
    /// @param mediaUrl_ The media URL of the IP asset being registered.
    function _registerIPAsset(
        IIPOrg ipOrg_,
        address owner_,
        string memory name_,
        uint8 ipOrgAssetType_,
        bytes32 hash_,
        string memory mediaUrl_
    ) internal returns (uint256 ipAssetId_, uint256 ipOrgAssetId_) {
        ipAssetId_ = IPA_REGISTRY.register(address(ipOrg_), owner_, name_, hash_);
        ipOrgAssetId_ = ipOrg_.mint(owner_, ipOrgAssetType_);
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
            ipOrgAssetType_,
            hash_,
            mediaUrl_
        );
    }

    /// @dev Transfers ownership of an IP asset to a new owner.
    /// @param ipOrg_ The address of the currently governing IP Org.
    /// @param ipOrgAssetId_ The local id of the IP asset within the IP Org.
    /// @param from_ The current owner of the IP asset within the IP Org.
    /// @param to_ The new owner of the IP asset within the IP Org.
    function _transferIPAsset(IIPOrg ipOrg_, uint256 ipOrgAssetId_, address from_, address to_) internal {
        ipOrg_.transferFrom(from_, to_, ipOrgAssetId_);
        uint256 id = ipAssetId[address(ipOrg_)][ipOrgAssetId_];
        emit IPAssetTransferred(id, address(ipOrg_), ipOrgAssetId_, from_, to_);
    }

    /// @dev Adds new IP asset types to an IP Org.
    /// @param ipOrg_ The address of the IP Org whose asset types we are adding.
    /// @param ipOrgTypes_ String descriptors of the asset types being added.
    /// TODO: Add ability to deprecate asset types.
    function _addIPAssetTypes(address ipOrg_, string[] memory ipOrgTypes_) internal {
        uint256 assetsLength = ipOrgTypes_.length;
        if (assetsLength > MAX_IP_ORG_ASSET_TYPES) {
            revert Errors.RegistrationModule_TooManyAssetTypes();
        }
        Registration.IPOrgConfig storage ipOrg = ipOrgConfigs[ipOrg_];
        for (uint256 i = 0; i < assetsLength; i++) {
            // TODO: this should be a set, and check empty strings
            ipOrg.assetTypes.push(ipOrgTypes_[i]);
        }
    }

    /// @dev Sets the IPOrg token and contract metadata.
    /// @param ipOrg_ The address of the IP Org whose metadata is changing.
    /// @param baseURI_ The new base URI to assign for the IP Org.
    /// @param contractURI_ The new base contract URI to assign for the IP Org.
    function _setMetadata(address ipOrg_, string memory baseURI_, string memory contractURI_) internal {
        Registration.IPOrgConfig storage config = ipOrgConfigs[ipOrg_];
        config.baseURI = baseURI_;
        config.contractURI = contractURI_;
        emit MetadataUpdated(ipOrg_, baseURI_, contractURI_);
    }

    /// @dev Verifies the caller of a configuration action.
    /// @param ipOrg_ The IP Org associated with the registration configuration.
    /// @param caller_ The address of the calling entity performing configuration.
    function _verifyConfigCaller(IIPOrg ipOrg_, address caller_) private view {
        if (ipOrg_.owner() != caller_ && address(IP_ORG_CONTROLLER) != caller_) {
            revert Errors.Unauthorized();
        }
    }

    /// @dev Verifies whether an IP Org asset type is valid.
    /// @param ipOrg_ Address of the IP Org under which the asset type lives.
    /// @param ipOrgAssetType_ The index used for identifying the IP asset type.
    function _verifyIpOrgAssetType(address ipOrg_, uint8 ipOrgAssetType_) private view {
        uint8 length = uint8(ipOrgConfigs[ipOrg_].assetTypes.length);
        if (ipOrgAssetType_ >= length) {
            revert Errors.RegistrationModule_InvalidIPAssetType();
        }
    }

    /// @dev Gets the hook registry key associated with an IP Org and execution type.
    /// @param ipOrg_ Address of the IP Org under which the hook is registered.
    /// @param moduleParams_ Registration config params from which the type is sourced.
    function _hookRegistryKey(
        IIPOrg ipOrg_,
        address,
        bytes calldata moduleParams_
    ) internal view virtual override returns (bytes32) {
        (bytes32 executionType, ) = abi.decode(moduleParams_, (bytes32, bytes));
        return _generateRegistryKey(ipOrg_, executionType);
    }

    /// @dev Creates a new hooks registration key for the registration module.
    /// @param ipOrg_ The IP Org under which the key is associated.
    function _generateRegistryKey(IIPOrg ipOrg_, bytes32 executionType_) private pure returns (bytes32) {
        return keccak256(abi.encode(address(ipOrg_), executionType_, "REGISTRATION"));
    }
}
