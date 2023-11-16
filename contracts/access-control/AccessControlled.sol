// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IAccessControlled } from "contracts/interfaces/access-control/IAccessControlled.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
// solhint-disable-next-line max-line-length
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

abstract contract AccessControlled is IAccessControlled {
    using ERC165CheckerUpgradeable for address;

    IAccessControl private _accessControl;

    /// @notice Checks if msg.sender has `role`, reverts if not.
    /// @param role_ the role to be tested, defined in Roles.sol and set in AccessManager instance.
    modifier onlyRole(bytes32 role_) {
        if (!hasRole(role_, msg.sender)) {
            revert Errors.MissingRole(role_, msg.sender);
        }
        _;
    }

    constructor(address accessControl_) {
        if (!accessControl_.supportsInterface(type(IAccessControl).interfaceId))
            revert Errors.UnsupportedInterface("IAccessControl");
        _accessControl = IAccessControl(accessControl_);
        emit AccessControlUpdated(accessControl_);
    }

    /// @notice Sets AccessManager instance. Restricted to PROTOCOL_ADMIN_ROLE
    /// @param accessControl_ address of the new instance of AccessControlSingleton.
    function setAccessControl(
        address accessControl_
    ) public onlyRole(AccessControl.PROTOCOL_ADMIN_ROLE) {
        if (!accessControl_.supportsInterface(type(IAccessControl).interfaceId))
            revert Errors.UnsupportedInterface("IAccessControl");
        _accessControl = IAccessControl(accessControl_);
        emit AccessControlUpdated(accessControl_);
    }

    /// @notice Checks if `account has `role` assigned.
    /// @param role_ the role to be tested, defined in Roles.sol and set in AccessManager instance.
    /// @param account_ the address to be tested for the role.
    /// @return return true if account has role, false otherwise.
    function hasRole(
        bytes32 role_,
        address account_
    ) internal view returns (bool) {
        return _accessControl.hasRole(role_, account_);
    }
}
