// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
// solhint-disable-next-line max-line-length
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IAccessControlled } from "contracts/interfaces/access-control/IAccessControlled.sol";

/// @title Access Controlled Contract
/// @notice This contract is to be inherited by any protocol components that require granular
///         roles for execution, as defined by the Access Control Singleton contract.
abstract contract AccessControlled is IAccessControlled {
    using ERC165CheckerUpgradeable for address;

    /// @notice Pointer to the global Access Control Singleton for protocol auth.
    IAccessControl private _accessControl;

    /// @notice Checks if msg.sender has `role`, reverts if not.
    /// @param role_ the role to be tested, defined in Roles.sol and set in AccessControlSingleton instance.
    modifier onlyRole(bytes32 role_) {
        if (!_hasRole(role_, msg.sender)) {
            revert Errors.MissingRole(role_, msg.sender);
        }
        _;
    }

    /// @notice Instantiates a new Access Controlled contract.
    /// @param accessControl_ The global Access Control Singleton contract address.
    constructor(address accessControl_) {
        if (!accessControl_.supportsInterface(type(IAccessControl).interfaceId))
            revert Errors.UnsupportedInterface("IAccessControl");
        _accessControl = IAccessControl(accessControl_);
        emit AccessControlUpdated(accessControl_);
    }

    /// @notice Sets AccessControlSingleton instance. Restricted to PROTOCOL_ADMIN_ROLE
    /// @param accessControl_ address of the new instance of AccessControlSingleton.
    function setAccessControl(address accessControl_) public onlyRole(AccessControl.PROTOCOL_ADMIN_ROLE) {
        if (!accessControl_.supportsInterface(type(IAccessControl).interfaceId))
            revert Errors.UnsupportedInterface("IAccessControl");
        _accessControl = IAccessControl(accessControl_);
        emit AccessControlUpdated(accessControl_);
    }

    /// @notice Checks if `account has role `role` assigned.
    /// @param role_ the role to be tested, defined in Roles.sol and set in AccessControlSingleton instance.
    /// @param account_ the address to be tested for the role.
    /// @return return True if account has role, False otherwise.
    function _hasRole(bytes32 role_, address account_) internal view returns (bool) {
        return _accessControl.hasRole(role_, account_);
    }
}
