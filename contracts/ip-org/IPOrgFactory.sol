// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IIPOrgController } from "contracts/interfaces/ip-org/IIPOrgController.sol";
import { IPOrg } from "contracts/ip-org/IPOrg.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";

/// @title IPOrg Factory Contract
/// @custom:version 0.1.0
/// TODO(leeren): Deprecate upgradeability once IPOrg contracts are finalized.
contract IPOrgController is
    UUPSUpgradeable,
    AccessControlledUpgradeable,
    IIPOrgController
{

    /// @notice Tracks ownership and registration of IPOrgs.
    /// TODO(leeren): Add tracking for allowlisted callers of each ipOrg.
    /// TODO(leeren): Add deterministic identifiers for ipOrgs using CREATE2.
    struct IPOrgRecord {
        address owner;
        address pendingOwner;
    }

    /// @custom:storage-location erc7201:story-protocol.ip-org-factory.storage
    struct IPOrgControllerStorage {
        /// @dev Tracks mappings from ipAssetOrg to whether they were registered.
        mapping(address => bool) registered;
    }

    bytes32 private constant _STORAGE_LOCATION = bytes32(uint256(keccak256("story-protocol.ip-org-factory.storage")) - 1);

    /// @notice Initializes the IPOrgController contract.
    /// @param accessControl_ Address of the contract responsible for access control.
    /// TODO(leeren): Deprecate this function in favor of an immutable factory.
    function initialize(address accessControl_) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl_);
    }

    /// @notice Checks if an address is a valid IP Asset Organization.
    /// @param ipAssetOrg_ the address to check
    /// @return true if `ipAssetOrg_` is a valid IP Asset Organization, false otherwise
    function isIpOrg(
        address ipAssetOrg_
    ) external view returns (bool) {
        IPOrgControllerStorage storage $ = _getIpOrgFactoryStorage();
        return $.registered[ipAssetOrg_];
    }

    /// @notice Registers a new ipAssetOrg for IP asset collection management.
    /// @param params_ Parameters required for ipAssetOrg creation.
    /// TODO: Converge on core primitives utilized for ipAssetOrg management.
    /// TODO: Add ipAssetOrg-wide module configurations to the registration process.
    /// TODO: Converge on access control for this method
    function registerIpOrg(
        address owner,
        IPOrgParams.RegisterIPOrgParams calldata params_
    ) public onlyRole(AccessControl.IPORG_CREATOR_ROLE) returns (address ipOrg) {
        // Check that the owner is a non-zero address.
        if (owner == address(0)) {
            revert Errors.ZeroAddress();
        }

        ipOrg = new IPOrg(params_);

        // Set the registration status of the IP Asset Org to be true.
        IPOrgControllerStorage storage $ = _getIpOrgFactoryStorage();
        $.registered[ipAssetOrg] = true;

        emit IPOrgRegistered(
            msg.sender,
            ipAssetOrg,
            params_.name,
            params_.symbol,
            params_.metadataUrl
        );
        return ipAssetOrg;

    }

    function _authorizeUpgrade(
        address newImplementation_
    ) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}

    function _getIpOrgFactoryStorage()
        private
        pure
        returns (IPOrgControllerStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
