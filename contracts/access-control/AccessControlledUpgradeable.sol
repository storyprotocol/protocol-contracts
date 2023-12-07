// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// solhint-disable-next-line max-line-length
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { IAccessControlled } from "contracts/interfaces/access-control/IAccessControlled.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Access Controlled Contract (upgradeable variant)
/// @notice This contract is to be inherited by any upgradeable protocol components that require 
///         granular roles for execution, as defined by the Access Control Singleton contract.
abstract contract AccessControlledUpgradeable is UUPSUpgradeable, IAccessControlled {
    using ERC165CheckerUpgradeable for address;

    /// @custom:storage-location erc7201:story-protocol.access-controlled-upgradeable.storage
    struct AccessControlledStorage {
        IAccessControl accessControl;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.access-controlled-upgradeable.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION =
        0x06c308ca3b780cede1217f5877d0c7fbf50796d93f836cb3b60e6457b0cf03b6;

    /// @notice Checks if msg.sender has `role`, reverts if not.
    /// @param role_ the role to be tested, defined in Roles.sol and set in AccessControlSingleton instance.
    modifier onlyRole(bytes32 role_) {
        if (!_hasRole(role_, msg.sender)) {
            revert Errors.MissingRole(role_, msg.sender);
        }
        _;
    }

    /// @notice Sets AccessControlSingleton instance. Restricted to PROTOCOL_ADMIN_ROLE
    /// @param accessControl_ address of the new instance of AccessControlSingleton.
    function setAccessControl(
        address accessControl_
    ) public onlyRole(AccessControl.PROTOCOL_ADMIN_ROLE) {
        if (!accessControl_.supportsInterface(type(IAccessControl).interfaceId))
            revert Errors.UnsupportedInterface("IAccessControl");
        AccessControlledStorage storage $ = _getAccessControlledUpgradeable();
        $.accessControl = IAccessControl(accessControl_);
        emit AccessControlUpdated(accessControl_);
    }

    /// @notice Gets the global Access Control Singleton configured for the protocol.
    function getAccessControl() public view returns (address) {
        AccessControlledStorage storage $ = _getAccessControlledUpgradeable();
        return address($.accessControl);
    }

    /// @notice Initializer method, access point to initialize inheritance tree.
    /// @param accessControl_ address of AccessControlSingleton.
    function __AccessControlledUpgradeable_init(
        address accessControl_
    ) internal initializer {
        if (!accessControl_.supportsInterface(type(IAccessControl).interfaceId))
            revert Errors.UnsupportedInterface("IAccessControl");
        AccessControlledStorage storage $ = _getAccessControlledUpgradeable();
        $.accessControl = IAccessControl(accessControl_);
        emit AccessControlUpdated(accessControl_);
    }

    /// @notice Checks if `account has `role` assigned.
    /// @param role_ the role to be tested, defined in Roles.sol and set in AccessControlSingleton instance.
    /// @param account_ the address to be tested for the role.
    /// @return return true if account has role, false otherwise.
    function _hasRole(
        bytes32 role_,
        address account_
    ) internal view returns (bool) {
        AccessControlledStorage storage $ = _getAccessControlledUpgradeable();
        return $.accessControl.hasRole(role_, account_);
    }

    /// @dev Helper function to get the EIP-7201 storage slot for the contract.
    function _getAccessControlledUpgradeable()
        private
        pure
        returns (AccessControlledStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
