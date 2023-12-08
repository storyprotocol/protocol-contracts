// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Access Control Singleton
/// @notice This contract serves as the global source of truth for role-based authorization.
///         Contracts that inherit the AccessControlled contract or its upgradable variant
///         are may be granted granular access to certain roles by utilizing the `onlyRole`
///         modifier with the required role input as a parameter.
contract AccessControlSingleton is AccessControlUpgradeable, UUPSUpgradeable, Multicall {
    /// @notice Initialize the Access Control Singleton contract.
    /// @param admin_ address to inherit the PROTOCOL_ADMIN_ROLE.
    function initialize(address admin_) external initializer {
        if (admin_ == address(0)) revert Errors.ZeroAddress();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(AccessControl.PROTOCOL_ADMIN_ROLE, admin_);
    }

    /// @notice Defines the admin role associated for a given protocol role.
    /// @param role_ The id of the new role, given by keccak256("<ROLE_NAME>").
    /// @param admin_ The id of the admin role provisioned for the provided role.
    function setRoleAdmin(bytes32 role_, bytes32 admin_) external onlyRole(AccessControl.PROTOCOL_ADMIN_ROLE) {
        _setRoleAdmin(role_, admin_);
    }

    /// @notice Authorizes an upgrade for the contract.
    function _authorizeUpgrade(address) internal virtual override onlyRole(AccessControl.UPGRADER_ROLE) {}
}
