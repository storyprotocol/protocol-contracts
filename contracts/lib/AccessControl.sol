// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

/// @title Access Control Library
/// @notice Library for access control helpers and protocol role definitions.
///         These roles are used by the AccessControlSingleton, accessed by AccessControlled contracts.
library AccessControl {

    // Default admin role as per OZ AccessControl system. All other roles stem from this.
    bytes32 constant PROTOCOL_ADMIN_ROLE = bytes32(0);

    // Role that can upgrade UUPS contracts or Beacon Proxies
    bytes32 constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Role that can perform admin tasks on the Protocol Relationship Module contract (e.g. adding new protocol-wide links)
    bytes32 constant RELATIONSHIP_MANAGER_ROLE = keccak256( "RELATIONSHIP_MANAGER_ROLE");

    // Role that can perform admin tasks on the Licensing Module contracts (setNonCommercialLicenseURI)
    bytes32 constant LICENSING_MANAGER_ROLE = keccak256("LICENSING_MANAGER_ROLE");

}
