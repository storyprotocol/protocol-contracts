// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

// solhint-disable-next-line max-line-length
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { IAccessControlled } from "contracts/interfaces/access-control/IAccessControlled.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Access Controlled Contract
/// @notice This contract is to be inherited by any protocol components that require granular
///         roles for execution, as defined by the Access Control Singleton contract. Later on,
///         this contract will be deprecated in favor of authorization through te module registry.
abstract contract AccessControlled is IAccessControlled {
    using ERC165CheckerUpgradeable for address;

    /// @notice Pointer to the global Access Control Singleton for protocol auth.
    IAccessControl private _accessControl;

    /// @notice Checks if msg.sender has role `role`, reverts otherwise.
    /// @param role_ The role being checked for, set by the Access Control Singleton.
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

    /// @notice Sets the Access Control Singleton used for authorization.
    /// @param accessControl_ The address of the new Access Control Singleton.
    function setAccessControl(address accessControl_) public onlyRole(AccessControl.PROTOCOL_ADMIN_ROLE) {
        if (!accessControl_.supportsInterface(type(IAccessControl).interfaceId))
            revert Errors.UnsupportedInterface("IAccessControl");
        _accessControl = IAccessControl(accessControl_);
        emit AccessControlUpdated(accessControl_);
    }

    /// @dev Checks if an account `account_` has role `role_` assigned.
    /// @param role_ The role being checked for as defined by the Access Control Singlton.
    /// @param account_ The address whose role permissions are being checked for.
    /// @return return True if the account has the role, False otherwise.
    function _hasRole(bytes32 role_, address account_) internal view returns (bool) {
        return _accessControl.hasRole(role_, account_);
    }
}
