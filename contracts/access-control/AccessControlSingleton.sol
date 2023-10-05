// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

import { PROTOCOL_ADMIN_ROLE, UPGRADER_ROLE } from "./ProtocolRoles.sol";
import { IVersioned } from "contracts/interfaces/utils/IVersioned.sol";
import { ZeroAddress } from "../errors/General.sol";
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
    /// @param _admin address to be the PROTOCOL_ADMIN_ROLE.
    function initialize(address _admin) external initializer {
        if (_admin == address(0)) revert ZeroAddress();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(PROTOCOL_ADMIN_ROLE, _admin);
    }

    
    /// @notice Method for PROTOCOL_ADMIN_ROLE to create new roles, and define their role admin.
    /// @param role id of the new role. Should be keccak256("<ROLE_NAME>").
    /// @param admin role id that will be the role admin for the new role.
    function setRoleAdmin(
        bytes32 role,
        bytes32 admin
    ) external onlyRole(PROTOCOL_ADMIN_ROLE) {
        _setRoleAdmin(role, admin);
    }

    
    /// @notice Access control for the upgrade process (UPGRADER_ROLE)
    /// @param newImplementation address of the new deployed implementation.
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}
}
