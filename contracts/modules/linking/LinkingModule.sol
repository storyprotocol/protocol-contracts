// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IIPAssetRegistry } from "contracts/ip-assets/IIPAssetRegistry.sol";
import { AccessControlledUpgradeable } from "contracts/access-control/AccessControlledUpgradeable.sol";
import { ZeroAddress, Unauthorized, UnsupportedInterface } from "contracts/errors/General.sol";
import { UPGRADER_ROLE, LINK_MANAGER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { FranchiseRegistry } from "contracts/FranchiseRegistry.sol";

contract LinkingModule is AccessControlledUpgradeable {

    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    
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

    event AddedFranchiseIntentRole(address franchise, bytes32 intent, bytes32 role);
    event RemovedFranchiseIntentRole(address franchise, bytes32 intent, bytes32 role);
    event AddedProtocolIntentRole(bytes32 intent, bytes32 role);
    event RemovedProtocolIntentRole(bytes32 intent, bytes32 role);

    error LinkingNonExistentToken();
    error IntentAlreadyRegistered();
    error UndefinedIntent();

    mapping(bytes32 => bool) public links;
    EnumerableSet.Bytes32Set private _franchiseIntents;
    mapping(bytes32 => bytes32) public franchiseIntentRole;
    mapping(bytes32 => bytes32) public protocolIntentRoles;


    bytes32 public constant PERMISSIONLESS_INTENT =
        keccak256("PERMISSIONLESS_INTENT");
    FranchiseRegistry public immutable FRANCHISE_REGISTRY;

    constructor(address franchiseRegistry) {
        if (franchiseRegistry == address(0)) revert ZeroAddress();
        FRANCHISE_REGISTRY = FranchiseRegistry(franchiseRegistry);
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
        if (IERC721(sourceContract).ownerOf(sourceId) == address(0)) revert LinkingNonExistentToken();
        if (IERC721(destContract).ownerOf(destId) == address(0)) revert LinkingNonExistentToken();
        if (sourceContract == destContract && _franchiseIntents.contains(intent)) {
            _verifyRole(franchiseIntentRole[keccak256(abi.encode(sourceContract, intent))]);
        } else {
            _verifyRole(protocolIntentRoles[intent]);
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
        if (IERC721(sourceContract).ownerOf(sourceId) == address(0)) revert LinkingNonExistentToken();
        if (IERC721(destContract).ownerOf(destId) == address(0)) revert LinkingNonExistentToken();

        // Whoever has the role of intent can unlink...does this make sense?
        if (sourceContract == destContract && _franchiseIntents.contains(intent)) {
            _verifyRole(franchiseIntentRole[keccak256(abi.encode(sourceContract, intent))]);
        } else {
            _verifyRole(protocolIntentRoles[intent]);
        }
        delete links[keccak256(abi.encode(sourceContract, sourceId, destContract, destId, intent))];
        emit Unlinked(sourceContract, sourceId, destContract, destId, intent);
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

    function _verifyRole(bytes32 intentRole) private view {
        if (intentRole == bytes32(0)) revert UndefinedIntent();
        if (intentRole != PERMISSIONLESS_INTENT) {
            if (!hasRole(intentRole, msg.sender)) revert Unauthorized();
        }
    }

    function _verifyIPAssetRegistry(address ipAssetRegistry, address franchiseOwner) private view {
        if (!ipAssetRegistry.supportsInterface(type(IIPAssetRegistry).interfaceId)) revert UnsupportedInterface("IIPAssetRegistry");
        uint256 franchiseId = IIPAssetRegistry(ipAssetRegistry).franchiseId();
        if (FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId) != ipAssetRegistry) revert Unauthorized();
        if (FRANCHISE_REGISTRY.ownerOf(franchiseId) != franchiseOwner) revert Unauthorized();
    }
    
    /********* Franchise level intents *********/

    function addFranchiseIntentRole(address ipAssetRegistry, bytes32 intent, bytes32 role) external {
        if (franchiseIntentRole[intent] != bytes32(0)) revert IntentAlreadyRegistered();
        if (protocolIntentRoles[intent] == bytes32(0)) revert IntentAlreadyRegistered();
        _verifyIPAssetRegistry(ipAssetRegistry, msg.sender);
        franchiseIntentRole[keccak256(abi.encode(ipAssetRegistry, intent))] = role;
        emit AddedFranchiseIntentRole(ipAssetRegistry, intent, role);
    }

    function removedFranchiseIntentRole(address ipAssetRegistry, bytes32 intent) external {
        if (franchiseIntentRole[intent] == bytes32(0)) revert UndefinedIntent();
        _verifyIPAssetRegistry(ipAssetRegistry, msg.sender);
        delete franchiseIntentRole[keccak256(abi.encode(ipAssetRegistry, intent))];
        emit RemovedFranchiseIntentRole(ipAssetRegistry, intent, franchiseIntentRole[intent]);
    }

    /********* Protocol level intents *********/

    function addProtocolIntentRole(bytes32 intent, bytes32 role) external onlyRole(LINK_MANAGER_ROLE) {
        if (protocolIntentRoles[intent] != bytes32(0)) revert IntentAlreadyRegistered();
        protocolIntentRoles[intent] = role;
        emit AddedProtocolIntentRole(intent, role);
    }

    function removeProtocolIntentRole(bytes32 intent) external onlyRole(LINK_MANAGER_ROLE) {
        if (protocolIntentRoles[intent] == bytes32(0)) revert UndefinedIntent();
        delete protocolIntentRoles[intent];
        emit RemovedProtocolIntentRole(intent, protocolIntentRoles[intent]);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {}
}