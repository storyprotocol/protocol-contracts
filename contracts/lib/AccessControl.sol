// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

/// @title Access Control Library
/// @notice Library for access control helpers and protocol role definitions.
///         These roles are used by the AccessControlSingleton, accessed by AccessControlled contracts.
library AccessControl {
    // Default admin role as per OZ AccessControl system. All other roles stem from this.
    bytes32 public constant PROTOCOL_ADMIN_ROLE = bytes32(0);

    // Role that can upgrade UUPS contracts or Beacon Proxies
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Role for managing protocol-wide and IP Org localized relationships.
    bytes32 public constant RELATIONSHIP_MANAGER_ROLE = keccak256("RELATIONSHIP_MANAGER_ROLE");

    // Role that can perform admin tasks on the Licensing Module contracts (setNonCommercialLicenseURI)
    bytes32 public constant LICENSING_MANAGER_ROLE = keccak256("LICENSING_MANAGER_ROLE");

    // Role that can add new modules to the Module Registry
    bytes32 public constant MODULE_REGISTRAR_ROLE = keccak256("MODULE_REGISTRAR_ROLE");

    // Role that can execute modules
    bytes32 public constant MODULE_EXECUTOR_ROLE = keccak256("MODULE_EXECUTOR_ROLE");

    // Role that can execute Hooks
    bytes32 public constant HOOK_CALLER_ROLE = keccak256("HOOK_CALLER_ROLE");

}
