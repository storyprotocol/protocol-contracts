// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { IVersioned } from "contracts/interfaces/utils/IVersioned.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @notice AccessControlSingleton contract. Manages protocol admin keys. Other contracts might inherit
/// AccessControlled or its upgradeable version to use the onlyRole modifier.
/// TODO: Evaluate making this contract AccessControlEnumerableUpgradeable so it could enforce unique roles
/// (as in only 1 address can have a role at a time)
contract AccessControlSingleton is
    AccessControlUpgradeable,
    UUPSUpgradeable,
    Multicall,
    IVersioned
{
    string public constant version = "0.1.0";

    /// @notice Initializer method, access point to initialize inheritance tree.
    /// @param admin_ address to be the PROTOCOL_ADMIN_ROLE.
    function initialize(address admin_) external initializer {
        if (admin_ == address(0)) revert Errors.ZeroAddress();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(AccessControl.PROTOCOL_ADMIN_ROLE, admin_);
    }

    /// @notice Method for PROTOCOL_ADMIN_ROLE to create new roles, and define their role admin.
    /// @param role_ id of the new role. Should be keccak256("<ROLE_NAME>").
    /// @param admin_ role id that will be the role admin for the new role.
    function setRoleAdmin(
        bytes32 role_,
        bytes32 admin_
    ) external onlyRole(AccessControl.PROTOCOL_ADMIN_ROLE) {
        _setRoleAdmin(role_, admin_);
    }

    /// @notice Access control for the upgrade process (UPGRADER_ROLE)
    /// @param newImplementation_ address of the new deployed implementation.
    function _authorizeUpgrade(
        address newImplementation_
    ) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}
}
