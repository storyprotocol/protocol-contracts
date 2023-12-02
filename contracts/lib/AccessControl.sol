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

    // Role that can call createIPOrg in the IPOrg Factory
    bytes32 constant IPORG_CREATOR_ROLE = keccak256("IPORG_CREATOR_ROLE");

    // Role that can add new modules to the Module Registry
    bytes32 constant MODULE_REGISTRAR_ROLE = keccak256("MODULE_REGISTRAR_ROLE");

    // Role that can execute modules
    bytes32 constant MODULE_EXECUTOR_ROLE = keccak256("MODULE_EXECUTOR_ROLE");

    // Role that can execute Hooks
    bytes32 constant HOOK_CALLER_ROLE = keccak256("HOOK_CALLER_ROLE");

    // Role to set legal terms in TermsRepository
    bytes32 constant LICENSING_MANAGER = keccak256("LICENSING_MANAGER");

}
