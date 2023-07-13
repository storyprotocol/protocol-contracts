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

    event AddedProtocolIntentRole(bytes32 intent, bytes32 role);
    event RemovedProtocolIntentRole(bytes32 intent, bytes32 role);

    error LinkingNonExistentToken();
    error IntentAlreadyRegistered();
    error UndefinedIntent();

    mapping(bytes32 => bool) public links;
    mapping(bytes32 => bytes32) public protocolIntentRoles;

    /*
    struct LinkParams {
        BitMaps.BitMap sourceIPAssetTypeMask;
        BitMaps.BitMap destIPAssetTypeMask;
        bool sameFranchiseOnly;
        address permissionChecker;
    }*/

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


    function _verifyIPAssetRegistry(address ipAssetRegistry, address franchiseOwner) private view {
        if (!ipAssetRegistry.supportsInterface(type(IIPAssetRegistry).interfaceId)) revert UnsupportedInterface("IIPAssetRegistry");
        uint256 franchiseId = IIPAssetRegistry(ipAssetRegistry).franchiseId();
        if (FRANCHISE_REGISTRY.ipAssetRegistryForId(franchiseId) != ipAssetRegistry) revert Unauthorized();
        if (FRANCHISE_REGISTRY.ownerOf(franchiseId) != franchiseOwner) revert Unauthorized();
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