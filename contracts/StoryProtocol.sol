// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IStoryProtocol } from "./IStoryProtocol.sol";
import { FranchiseRegistry } from "./FranchiseRegistry.sol";
import { AccessControlledUpgradeable } from "./access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE } from "./access-control/ProtocolRoles.sol";
import { ZeroAddress } from "./errors/General.sol";
import { DataTypes } from './libraries/DataTypes.sol';
import { IVersioned } from "./utils/IVersioned.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { Multicall } from "@openzeppelin/contracts/utils/Multicall.sol";

contract StoryProtocol is
    UUPSUpgradeable,
    IVersioned,
    AccessControlledUpgradeable,
    IStoryProtocol,
    Multicall
{

    /// @custom:storage-location erc7201:story-protocol.story-protocol.storage
    struct StoryProtocolStorage {
        // empty struct is not allowed in solidity
        // Todo: this placeholder should be removed when actual attributes was added
        uint8 placeholder;
    }

    FranchiseRegistry public immutable FRANCHISE_REGISTRY;
    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.story-protocol.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x9caed356793f27a747b517e5e83e1c0a6c55216c64745151280d9b5cf626fe9b;
    string private constant _VERSION = "0.1.0";


    constructor(address _franchiseRegistry) {
        if (_franchiseRegistry == address(0)) revert ZeroAddress();
        FRANCHISE_REGISTRY = FranchiseRegistry(_franchiseRegistry);
        _disableInitializers();
    }

    function initialize(address accessControl) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl);
    }

    function _getStoryProtocolStorage() private pure returns (StoryProtocolStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function version() external pure override returns (string memory) {
        return _VERSION;
    }

    function registerFranchise(DataTypes.FranchiseCreationParams calldata params) external returns (uint256, address) {
        return FRANCHISE_REGISTRY.registerFranchise(params);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}