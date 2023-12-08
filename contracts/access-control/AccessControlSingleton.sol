// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf

pragma solidity ^0.8.19;

import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { IVersioned } from "contracts/interfaces/utils/IVersioned.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @title Access Control Singleton
/// @notice This contract serves as the global source of truth for role-based authorization.
///         Contracts that inherit the AccessControlled contract or its upgradable variant
///         are may be granted granular access to certain roles by utilizing the `onlyRole`
///         modifier with the required role input as a parameter.
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
