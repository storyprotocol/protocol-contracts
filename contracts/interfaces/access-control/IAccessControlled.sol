// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Access Controlled Interface
interface IAccessControlled {

    event AccessControlUpdated(address indexed accessControl);

    /// @notice Sets AccessControlSingleton instance.
    /// @param accessControl_ address of the new instance of AccessControlSingleton.
    function setAccessControl(address accessControl_) external;
}
