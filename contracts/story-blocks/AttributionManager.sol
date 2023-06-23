// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Unauthorized } from "../errors/General.sol";

/**
 * @title AttributionManager
 * @dev Manages attribution on StoryBlocks.
 * The contract allows RBAC for attribution roles, with the owner of the StoryBlock as the admin.
 */
abstract contract AttributionManager is
    ERC721Upgradeable,
    AccessControlUpgradeable
{
    bytes32 public constant CONTRIBUTOR_ROLE = keccak256("CONTRIBUTOR_ROLE");

    modifier onlyOwnerOrRoleAdmin(uint256 id, bytes32 role) {
        if (ownerOf(id) != msg.sender && !hasRole(getRoleAdmin(roleKey(id, role)), msg.sender)) revert Unauthorized();
        _;
    }

    function __AttributionManager_init(string calldata name, string calldata symbol) public initializer {
        __ERC721_init(name, symbol);
        __AccessControl_init();
    }

    // Helper to compress id and role as key to save storage r/w
    function roleKey(uint256 id, bytes32 role) public pure returns (bytes32) {
        return keccak256(abi.encode(id, role));
    }

    // ****** Explicit methods *****
    function grantContributor(uint256 id, address contributor) public {
        if (ownerOf(id) != msg.sender) revert Unauthorized();
        _grantRole(roleKey(id, CONTRIBUTOR_ROLE), contributor);
    }

    function revokeContributor(uint256 id, address contributor) external {
        if (ownerOf(id) != msg.sender) revert Unauthorized();
        _revokeRole(roleKey(id, CONTRIBUTOR_ROLE), contributor);
    }

    function renounceContributor(uint256 id) external {
        _revokeRole(roleKey(id, CONTRIBUTOR_ROLE), msg.sender);
    }

    function isContributor(uint256 id, address contributor) public view returns (bool) {
        return hasRole(roleKey(id, CONTRIBUTOR_ROLE), contributor);
    }

    // ****** Generalizable methods *****
    function grantAttribution(uint256 id, bytes32 role, address contributor) external onlyOwnerOrRoleAdmin(id, role) {
        _grantRole(roleKey(id, role), contributor);
    }

    function revokeAttribution(uint256 id, bytes32 role, address contributor) external onlyOwnerOrRoleAdmin(id, role) {
        _revokeRole(roleKey(id, role), contributor);
    }

    function renounceAttribution(uint256 id, bytes32 role) external {
        _revokeRole(roleKey(id, role), msg.sender);
    }

    function setRoleAdmin(uint256 id, bytes32 role, bytes32 adminRole) external onlyOwnerOrRoleAdmin(id, role) {
        _setRoleAdmin(roleKey(id, role), adminRole);
    }

    function getRoleAdmin(uint256 id, bytes32 role) public view returns (bytes32) {
        return getRoleAdmin(roleKey(id, role));
    }

    function hasAttribution(uint256 id, bytes32 role, address contributor) public view returns (bool) {
        return hasRole(keccak256(abi.encode(id, role)), contributor);
    }

    // Overrides to prevent direct role manipulation AccessControl style
    function grantRole(bytes32, address) public pure override {
        revert Unauthorized();
    }

    function revokeRole(bytes32, address) public pure override {
        revert Unauthorized();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
