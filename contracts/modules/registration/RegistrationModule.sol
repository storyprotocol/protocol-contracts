// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { IRegistrationModule } from "contracts/interfaces/modules/registration/IRegistrationModule.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { LibUintArrayMask } from "contracts/lib/LibUintArrayMask.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Registration Module
/// @notice Handles registration and transferring of IP assets..
contract RegistrationModule is BaseModule, IRegistrationModule, AccessControlled {

    using Strings for uint256;

    /// @notice Mapping of IP Orgs to their IPA configuration settings.
    mapping(address => Registration.IPOrgConfig) ipOrgConfigs;

    /// @notice Reverse lookup from IP Org asset to GIPR asset ids.
    mapping(address => mapping(uint256 => uint256)) public ipAssetIds;

    constructor(
        BaseModule.ModuleConstruction memory params_,
    ) BaseModule(params_) {}

    /// @notice Gets the contract URI for an IP Org.
    function contractURI(address ipOrg) {
        string contractURI = ipOrgConfigs[ipOrg].contractURI;
        if (bytes(uri).length == 0) {
            revert Errors.RegistrationModule_IPOrgNotConfigured();
        }
        return contractURI;
    }

    /// @notice Renders metadata of an IP Asset localized for an IP Org.
    /// TODO(leeren) Add per-IPOrg metadata renderers configurable through this module.
    function tokenURI(address ipOrg, uint256 ipOrgAssetId) {
        uint256 ipAssetId = ipAssetIds[ipOrg][ipOrgAssetId];
        address owner = IPOrg(ipOrg).ownerOf(ipOrgAssetId);
        if (owner == address(0)) {
            revert Errors.RegistrationModule_IPAssetNonExistent();
        }
        IPOrgConfig memory config = ipOrgConfigs[ipOrg];
        if (bytes(config.baseURI).length != 0) {
            return string(abi.encodePacked(
                config.baseURI,
                Strings.toString(ipAssetId),
            ));
        }

        IPA memory ipa = ipaRegistry.ipAssets(ipAssetId);

        // Construct the base JSON metadata with custom name format
        string memory baseJson = string(abi.encodePacked(
            '{"name": "Global IP Asset #', Strings.toString(ipAssetId),
            ': ', ipAsset.name,
            '", "description": "IP Org Asset Registration Details", "attributes": ['
        ));

        // Parse individual GIPR attributes
        string memory attributes = string(abi.encodePacked(
            '{"trait_type": "Current IP Owner", "value": "', Strings.toHexString(uint160(owner), 20), '"},',
            '{"trait_type": "IP Asset Type", "value": "', Strings.toString(ipAsset.ipAssetType), '"},',
            '{"trait_type": "Status", "value": "', Strings.toString(ipAsset.status), '"},',
            '{"trait_type": "Registrant", "value": "', Strings.toHexString(uint160(ipAsset.registrant), 20), '"},',
            '{"trait_type": "IP Org", "value": "', Strings.toHexString(uint160(ipAsset.ipOrg), 20), '"},',
            '{"trait_type": "Hash", "value": "', Strings.toHexString(uint256(ipAsset.hash), 32), '"},',
            '{"trait_type": "Registration Date", "value": "', Strings.toString(ipAsset.registrationDate), '"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string(abi.encodePacked(baseJson, attributes, ']}'))
                )
            )
        );
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

    function _configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal {
        if (ipOrg_.owner() != caller_) {
            revert Errors.RegistrationModule_CallerNotAuthorized();
        }
        IPOrgConfig memory config = abi.decode(params_, (IPOrgConfig));
    }

    /// @notice Registers an IP Asset.
    /// @param params_ encoded RegisterIPAParams for module action
    /// @return encoded registry and IP Org id of the IP asset.
    function _performAction(IIPOrg ipOrg_, address caller_, bytes calldata params_) virtual override internal returns (bytes memory) {
        Registration.RegisterIPAParams memory params = abi.decode(params_, (Registration.RegisterIPAParams));
        (uint256 ipAssetId, uint256 ipOrgAssetId) = ipOrg_.register(
            params.owner,
            params.name,
            params.ipAssetType,
            params.hash
        );

        ipAssetIds[address(ipOrg_)][ipOrgAssetId] = registryId;

        emit IPAssetRegistered(
            ipAssetId,
            ipOrg_,
            ipOrgAssetId,
            params.owner_,
            params.name_,
            params.ipAssetType_,
            params.hash_
        );
        return abi.encode(ipAssetId, ipOrgAssetId);
    }

    function _registerIPAsset(
        IIPOrg ipOrg_,
        address owner_,
        string name_,
        uint64 ipAssetType_,
        bytes32 hash_
    ) internal returns (uint256 ipAssetId, uint256 ipOrgAssetId) {
        ipAssetId = IPA_REGISTRY.register(
            owner_,
            name_,
            ipAssetType_,
            hash_,
        );
        ipOrgAssetId = ipOrg_.mint();
        ipAssetIds[address(ipOrg_)][ipOrgAssetId] = ipAssetId;
        emit IPAssetRegistered(
            ipAssetId,
            ipOrg_,
            ipOrgAssetId,
            owner_,
            name_,
            ipAssetType_,
            hash_
        );
    }

    function _transferIPOrg(
        IIPOrg ipOrg_,
        uint256 ipOrgAssetId_,
        address newIpOrg_,
    ) {
        uint256 ipAssetId = ipAssetIds[ipOrg][ipOrgAssetId];
        ipOrg_.burn(ipOrgAssetId_);
        delete ipAssetIds[address(ipOrg_)][ipOrgAssetId];
        ipAssetId = IPA_REGISTRY.transferIPOrg(
            ipAssetId,
            newIpOrg_
        );
        ipOrgAssetId = newIpOrg_.mint();
        ipAssetIds[address(ipOrg_)][ipOrgAssetId] = ipAssetId;
    }

    function _transferIPAsset(
        IIPOrg ipOrg_,
        uint256 ipOrgAssetId_,
        address from_,
        address to_
    ) internal returns (uint256 ipAssetId, uint256 ipOrgAssetId) {
        ipOrg_.transferFrom(from_, to_, ipOrgAssetId_);
        ipAssetIds[address(ipOrg_)][ipOrgAssetId] = ipAssetId;
        emit IPAssetTransferred(
            address(ipOrg_),
            ipOrgAssetId_,
            from_,
            to_,
        );
    }
}
