// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Access Controlled Interface
interface IAccessControlled {

    /// @notice Emits when the global Access Control singleton contract is updated.
    /// @param accessControl Address of the protocol-wide Access Control singleton contract.
    event AccessControlUpdated(address indexed accessControl);

}
