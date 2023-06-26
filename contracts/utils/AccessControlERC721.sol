// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import { ERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { NonExistentID } from "../errors/General.sol";


/**
 * @dev RBAC where the main admin role is held by an NFT owner.
 * Each nft id can define its own hierarchy of roles.
 * Inspired by OpenZeppelin's AccessControl.sol
 */
abstract contract AccessControlERC721 is ERC721Upgradeable {

    event RoleAdminChanged(uint256 indexed id, bytes32 indexed role, bytes32 previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(uint256 indexed id, bytes32 indexed role, address indexed account, address sender);
    event RoleRevoked(uint256 indexed id, bytes32 indexed role, address indexed account, address sender);

    error MissingRole(uint256 id, bytes32 role, address account);
    error NotNFTOwnerOrRoleAdmin(uint256 id, bytes32 role, address account);
    error OnlySelfCanRenounce();
    error CannotGrantNFTOwner();

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRoleKey;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant _NFT_OWNER_ROLE = 0x00;


    modifier onlyRole(uint256 id, bytes32 role) {
        _checkRole(id, role);
        _;
    }

    modifier onlyRoleAdminOrNFTOwner(uint256 id, bytes32 role) {
        bytes32 roleAdmin = getAdminRolekey(id, role);
        if ((roleAdmin != _NFT_OWNER_ROLE || ownerOf(id) != msg.sender) && !hasRole(id, roleAdmin, msg.sender)) {
            revert NotNFTOwnerOrRoleAdmin(id, role, msg.sender);
        }
        _;
    }

    function __AccessControlERC721_init(string calldata name, string calldata symbol) internal onlyInitializing {
        __ERC721_init(name, symbol);
    }

    function __AccessControlERC721_init_unchained(string calldata name, string calldata symbol) internal onlyInitializing {
        __ERC721_init(name, symbol);
    }

    function getRoleKey(uint256 id, bytes32 role) public pure returns (bytes32) {
        return keccak256(abi.encode(id, role));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(uint256 id, bytes32 role, address account) public view returns (bool) {
        if (role == _NFT_OWNER_ROLE) {
            return ownerOf(id) == account;
        }
        return _roles[getRoleKey(id, role)].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(uint256 id, bytes32 role) internal view  {
        _checkRole(id, role, msg.sender);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(uint256 id, bytes32 role, address account) internal view  {
        if (!hasRole(id, role, account)) {
            revert MissingRole(id, role, account);
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getAdminRolekey(uint256 id, bytes32 role) public view returns (bytes32) {
        return _roles[getRoleKey(id, role)].adminRoleKey;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(uint256 id, bytes32 role, address account) public onlyRoleAdminOrNFTOwner(id, role) {
        _grantRole(id, role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(uint256 id, bytes32 role, address account) public onlyRoleAdminOrNFTOwner(id, role) {
        _revokeRole(id, role, account);
    }

    function setRoleAdmin(uint256 id, bytes32 role, bytes32 adminRole) public onlyRoleAdminOrNFTOwner(id, role) {
        _setRoleAdmin(id, role, adminRole);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(uint256 id, bytes32 role, address account) public   {
        if (account != msg.sender) {
            revert OnlySelfCanRenounce();
        }

        _revokeRole(id, role, account);
    }

    /**
     * @dev Sets `adminRoleKey` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(uint256 id, bytes32 role, bytes32 adminRole) internal  {
        bytes32 previousAdminRoleKey = getAdminRolekey(id, role);
        bytes32 newAdminRoleKey = getRoleKey(id, adminRole); 
        _roles[getRoleKey(id, role)].adminRoleKey = newAdminRoleKey;
        emit RoleAdminChanged(id, role, previousAdminRoleKey, newAdminRoleKey);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(uint256 id, bytes32 role, address account) internal  {
        if (role == _NFT_OWNER_ROLE) {
            revert CannotGrantNFTOwner();
        }
        // Note: _exists(id) will revert if id does not exist.
        if (_exists(id) && !hasRole(id, role, account)) {
            bytes32 rk = getRoleKey(id, role);
            _roles[rk].members[account] = true;
            emit RoleGranted(id, role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(uint256 id, bytes32 role, address account) internal  {
        if (hasRole(id, role, account)) {
            bytes32 rk = getRoleKey(id, role);
            _roles[rk].members[account] = false;
            emit RoleRevoked(id, role, account, msg.sender);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
