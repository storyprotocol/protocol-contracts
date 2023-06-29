// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { UPGRADER_ROLE, LINK_MANAGER_ROLE } from "contracts/access-control/ProtocolRoles.sol";

contract LinkingModule is AccessControlledUpgradeable {
    
    event Linked(
        address col1,
        uint256 id1,
        address col2,
        uint256 id2,
        bytes32 intent
    );
    event Unlinked(
        address col1,
        uint256 id1,
        address col2,
        uint256 id2,
        bytes32 intent
    );
    event AddedIntentRole(bytes32 intent, bytes32 role);
    event RemovedIntentRole(bytes32 intent, bytes32 role);

    error LinkingNonExistentToken();
    error IntentAlreadyRegistered();
    error NonExistentIntent();

    mapping(bytes32 => bool) public links;
    mapping(bytes32 => bytes32) public intentRoles;


    bytes32 public constant PERMISSIONLESS_INTENT =
        keccak256("PERMISSIONLESS_INTENT");

    constructor() {
        _disableInitializers();
    }

    function initialize(address accessControl) public initializer {
        __AccessControlledUpgradeable_init(accessControl);
    }

    function link(
        address col1,
        uint256 id1,
        address col2,
        uint256 id2,
        bytes32 intent
    ) external {
        _verifyLink(col1, id1, col2, id2);

        bytes32 intentRole = intentRoles[intent];
        if (intentRole != PERMISSIONLESS_INTENT) {
            if (!hasRole(intentRole, msg.sender)) revert Unauthorized();
        }
        links[keccak256(abi.encode(col1, id1, col2, id2, intent))] = true;
        emit Linked(col1, id1, col2, id2, intent);
    }

    function unlink(
        address col1,
        uint256 id1,
        address col2,
        uint256 id2,
        bytes32 intent
    ) external {
        // Whoever has the role of intent can unlink...does this make sense?
        bytes32 intentRole = intentRoles[intent];
        if (intentRole != PERMISSIONLESS_INTENT) {
            if (!hasRole(intentRole, msg.sender)) revert Unauthorized();
        }
        delete links[keccak256(abi.encode(col1, id1, col2, id2, intent))];
        emit Unlinked(col1, id1, col2, id2, intent);
    }

    function _verifyLink(
        address col1,
        uint256 id1,
        address col2,
        uint256 id2
    ) internal view {
        if (IERC721(col1).ownerOf(id1) == address(0)) revert LinkingNonExistentToken();
        if (IERC721(col2).ownerOf(id2) == address(0)) revert LinkingNonExistentToken();       
    }

    function areTheyLinked(
        address col1,
        uint256 id1,
        address col2,
        uint256 id2,
        bytes32 intent
    ) external view returns (bool) {
        return links[keccak256(abi.encode(col1, id1, col2, id2, intent))];
    }

    function addIntentRole(bytes32 intent, bytes32 role) external onlyRole(LINK_MANAGER_ROLE) {
        if (intentRoles[intent] != bytes32(0)) revert IntentAlreadyRegistered();
        intentRoles[intent] = role;
        emit AddedIntentRole(intent, role);
    }

    function removeIntentRole(bytes32 intent) external onlyRole(LINK_MANAGER_ROLE) {
        if (intentRoles[intent] == bytes32(0)) revert NonExistentIntent();
        delete intentRoles[intent];
        emit RemovedIntentRole(intent, intentRoles[intent]);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {}
}