// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Access Controlled Interface
/// @notice This interface must be implemented by all protocol components that require
///         to be authorized via the global Access Control Singleton contract. This
///         initially includes all modules and hooks contracts, but will later be
///         sunset in favor of central authorization via the module registry.
interface IAccessControlled {
    /// @notice Emits when the global Access Control Singleton contract is updated.
    /// @param accessControl Address of the protocol-wide Access Control singleton contract.
    event AccessControlUpdated(address indexed accessControl);

    /// @notice Sets the Access Control Singleton instance.
    /// @param accessControl_ address of the new instance of the Access Control Singleton.
    function setAccessControl(address accessControl_) external;
}
