// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

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

    /// @notice Reverse lookup from IP Org to GIPR asset ids.
    mapping(address => mapping(uint256 => uint256)) public registryIds;

    constructor(
        BaseModule.ModuleConstruction memory params_,
    ) BaseModule(params_) {}

    /// @notice Renders metadata of an IP Asset localized for an IP Org.
    /// TODO(leeren) Add per-IPOrg metadata renderers configurable through this module.
    function renderMetadata(address ipOrg, uint256 ipOrgAssetId) {
    }

    function _setMetadataRenderer(
        address ipOrg_,
        IMetadataRenderer renderer_,
        bytes memory rendererData
    ) internal {
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

        registryIds[address(ipOrg_)][ipOrgAssetId] = registryId;

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

}
