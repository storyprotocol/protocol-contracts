// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { ERC165CheckerUpgradeable }
    from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { PROTOCOL_ADMIN_ROLE } from "./ProtocolRoles.sol";
import { UnsupportedInterface } from "../errors/General.sol";

abstract contract AccessControlled {

    using ERC165CheckerUpgradeable for address;

    IAccessControl private _accessControl;

    event AccessControlUpdated(address indexed accessControl);
    error MissingRole(bytes32 role, address account);

    /**
     * @notice Checks if msg.sender has `role`, reverts if not.
     * @param role the role to be tested, defined in Roles.sol and set in AccessManager instance.
     */
    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) {
            revert MissingRole(role, msg.sender);
        }
        _;
    }

    constructor(address accessControl) {
        if (!accessControl.supportsInterface(type(IAccessControl).interfaceId))
            revert UnsupportedInterface("IAccessControl");
        _accessControl = IAccessControl(accessControl);
        emit AccessControlUpdated(accessControl);
    }

    /**
     * @notice Checks if `account has `role` assigned.
     * @param role the role to be tested, defined in Roles.sol and set in AccessManager instance.
     * @param account the address to be tested for the role.
     * @return return true if account has role, false otherwise.
     */
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return _accessControl.hasRole(role, account);
    }

    /**
     * @notice Sets AccessManager instance. Restricted to PROTOCOL_ADMIN_ROLE
     * @param accessControl address of the new instance of AccessControlSingleton.
     */
    function setAccessControl(address accessControl) public onlyRole(PROTOCOL_ADMIN_ROLE) {
        if (!accessControl.supportsInterface(type(IAccessControl).interfaceId))
            revert UnsupportedInterface("IAccessControl");
        _accessControl = IAccessControl(accessControl);
        emit AccessControlUpdated(accessControl);
    }

}