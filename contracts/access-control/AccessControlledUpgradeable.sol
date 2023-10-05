// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.9;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// solhint-disable-next-line max-line-length
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { PROTOCOL_ADMIN_ROLE } from "./ProtocolRoles.sol";
import { UnsupportedInterface } from "../errors/General.sol";

abstract contract AccessControlledUpgradeable is UUPSUpgradeable {
    using ERC165CheckerUpgradeable for address;

    event AccessControlUpdated(address indexed accessControl);
    error MissingRole(bytes32 role_, address account_);

    /// @custom:storage-location erc7201:story-protocol.access-controlled-upgradeable.storage
    struct AccessControlledStorage {
        IAccessControl accessControl;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.access-controlled-upgradeable.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION =
        0x06c308ca3b780cede1217f5877d0c7fbf50796d93f836cb3b60e6457b0cf03b6;

    /// @notice Checks if msg.sender has `role`, reverts if not.
    /// @param role_ the role to be tested, defined in Roles.sol and set in AccessManager instance.
    modifier onlyRole(bytes32 role_) {
        if (!hasRole(role_, msg.sender)) {
            revert MissingRole(role_, msg.sender);
        }
        _;
    }

    /// @notice Initializer method, access point to initialize inheritance tree.
    /// @param accessControl_ address of AccessManager.
    function __AccessControlledUpgradeable_init(
        address accessControl_
    ) internal initializer {
        if (!accessControl_.supportsInterface(type(IAccessControl).interfaceId))
            revert UnsupportedInterface("IAccessControl");
        AccessControlledStorage storage $ = _getAccessControlledUpgradeable();
        $.accessControl = IAccessControl(accessControl_);
        emit AccessControlUpdated(accessControl_);
    }

    function _getAccessControlledUpgradeable()
        private
        pure
        returns (AccessControlledStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    /// @notice Checks if `account has `role` assigned.
    /// @param role_ the role to be tested, defined in Roles.sol and set in AccessManager instance.
    /// @param account_ the address to be tested for the role.
    /// @return return true if account has role, false otherwise.
    function hasRole(
        bytes32 role_,
        address account_
    ) internal view returns (bool) {
        AccessControlledStorage storage $ = _getAccessControlledUpgradeable();
        return $.accessControl.hasRole(role_, account_);
    }

    /// @notice Sets AccessManager instance. Restricted to PROTOCOL_ADMIN_ROLE
    /// @param accessControl_ address of the new instance of AccessControlSingleton.
    function setAccessControl(
        address accessControl_
    ) public onlyRole(PROTOCOL_ADMIN_ROLE) {
        if (!accessControl_.supportsInterface(type(IAccessControl).interfaceId))
            revert UnsupportedInterface("IAccessControl");
        AccessControlledStorage storage $ = _getAccessControlledUpgradeable();
        $.accessControl = IAccessControl(accessControl_);
        emit AccessControlUpdated(accessControl_);
    }

    function getAccessControl() public view returns (address) {
        AccessControlledStorage storage $ = _getAccessControlledUpgradeable();
        return address($.accessControl);
    }
}
