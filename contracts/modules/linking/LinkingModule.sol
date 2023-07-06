// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ZeroAddress, Unauthorized } from "contracts/errors/General.sol";
import { UPGRADER_ROLE, LINK_MANAGER_ROLE } from "contracts/access-control/ProtocolRoles.sol";

contract LinkingModule is AccessControlledUpgradeable {
    
    event Linked(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 intent
    );
    event Unlinked(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 intent
    );
    event AddedIntentRole(bytes32 intent, bytes32 role);
    event RemovedIntentRole(bytes32 intent, bytes32 role);

    error LinkingNonExistentToken();
    error IntentAlreadyRegistered();
    error UndefinedIntent();

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
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 intent
    ) external {
        _verifyLink(sourceContract, sourceId, destContract, destId, intent);
        bytes32 intentRole = intentRoles[intent];
        if (intentRole == bytes32(0)) revert UndefinedIntent();
        if (intentRole != PERMISSIONLESS_INTENT) {
            if (!hasRole(intentRole, msg.sender)) revert Unauthorized();
        }
        links[keccak256(abi.encode(sourceContract, sourceId, destContract, destId, intent))] = true;
        emit Linked(sourceContract, sourceId, destContract, destId, intent);
    }

    function unlink(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 intent
    ) external {
        // Whoever has the role of intent can unlink...does this make sense?
        bytes32 intentRole = intentRoles[intent];
        if (intentRole != PERMISSIONLESS_INTENT) {
            if (!hasRole(intentRole, msg.sender)) revert Unauthorized();
        }
        delete links[keccak256(abi.encode(sourceContract, sourceId, destContract, destId, intent))];
        emit Unlinked(sourceContract, sourceId, destContract, destId, intent);
    }

    function _verifyLink(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 intent
    ) internal view {
        if (IERC721(sourceContract).ownerOf(sourceId) == address(0)) revert LinkingNonExistentToken();
        if (IERC721(destContract).ownerOf(destId) == address(0)) revert LinkingNonExistentToken();

    }

    function areTheyLinked(
        address sourceContract,
        uint256 sourceId,
        address destContract,
        uint256 destId,
        bytes32 intent
    ) external view returns (bool) {
        return links[keccak256(abi.encode(sourceContract, sourceId, destContract, destId, intent))];
    }

    function addIntentRole(bytes32 intent, bytes32 role) external onlyRole(LINK_MANAGER_ROLE) {
        if (intentRoles[intent] != bytes32(0)) revert IntentAlreadyRegistered();
        intentRoles[intent] = role;
        emit AddedIntentRole(intent, role);
    }

    function removeIntentRole(bytes32 intent) external onlyRole(LINK_MANAGER_ROLE) {
        if (intentRoles[intent] == bytes32(0)) revert UndefinedIntent();
        delete intentRoles[intent];
        emit RemovedIntentRole(intent, intentRoles[intent]);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {}
}