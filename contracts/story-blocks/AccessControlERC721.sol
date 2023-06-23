// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import { ERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

abstract contract AccessControlERC721 is ERC721Upgradeable {

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(uint256 indexed id, bytes32 indexed role, bytes32 previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(uint256 indexed id, bytes32 indexed role, address indexed account, address sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(uint256 indexed id, bytes32 indexed role, address indexed account, address sender);

    error MissingRole(uint256 id, bytes32 role, address account);

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRoleKey;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant _NFT_OWNER_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(uint256 id, bytes32 role) {
        _checkRole(id, role);
        _;
    }

    modifier onlyRoleAdminOrNFTOwner(uint256 id, bytes32 role) {
        if (ownerOf(id) != msg.sender && !hasRole(id, role, msg.sender)) {
            _checkRole(id, role);
        }
        _;
    }


    function __AttributableERC721_init(string calldata name, string calldata symbol) internal onlyInitializing {
        __ERC721_init(name, symbol);
    }

    function __AttributionManater_init_unchained(string calldata name, string calldata symbol) internal onlyInitializing {
        __ERC721_init(name, symbol);
    }

    function roleKey(uint256 id, bytes32 role) public pure returns (bytes32) {
        return keccak256(abi.encode(id, role));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(uint256 id, bytes32 role, address account) public view   returns (bool) {
        return _roles[roleKey(id, role)].members[account];
    }

    function isRoleAdmin(uint256 id, bytes32 role, address account) public view returns (bool) {
        return _roles[roleKey(id, role)].adminRoleKey
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
    function getRoleAdmin(uint256 id, bytes32 role) public view returns (bytes32) {
        return _roles[roleKey(id, role)].adminRoleKey;
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
    function grantRole(uint256 id, bytes32 role, address account) public  onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(uint256 id, bytes32 role, address account) public  onlyRole(getRoleAdmin(role)) {
        _revokeRole(id, role, account);
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
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

        _revokeRole(id, role, account);
    }

    /**
     * @dev Sets `adminRoleKey` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(uint256 id, bytes32 role, bytes32 adminRole) internal  {
        bytes32 previousAdminRoleKey = getRoleAdmin(id, role);
        bytes32 newAdminRoleKey = roleKey(id, adminRole); 
        _roles[roleKey(id, role)].adminRoleKey = newAdminRoleKey;
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
        if (!hasRole(id, role, account)) {
            bytes32 rk = roleKey(id, role);
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
            bytes32 rk = roleKey(id, role);
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
