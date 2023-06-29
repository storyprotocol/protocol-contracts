// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { StoryBlock } from "./StoryBlock.sol";
import { StoryBlocksRegistryFactory } from "./story-blocks/StoryBlocksRegistryFactory.sol";
import { AccessControlledUpgradeable } from "./access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE } from "./access-control/ProtocolRoles.sol";
import { ZeroAddress } from "./errors/General.sol";
import { IVersioned } from "./utils/IVersioned.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract FranchiseRegistry is
    UUPSUpgradeable,
    IVersioned,
    AccessControlledUpgradeable,
    ERC721Upgradeable
{
    event FranchiseRegistered(
        address owner,
        uint256 id,
        address storyBlockRegistryForId
    );
    error AlreadyRegistered();

    uint256 _franchiseIds;
    /// Franchise id => StoryBlockRegistry address
    mapping(uint256 => address) public _storyBlockRegistries;

    StoryBlocksRegistryFactory public immutable FACTORY;
    uint256 public constant PROTOCOL_ROOT_ID = 0;
    address public constant PROTOCOL_ROOT_ADDRESS = address(0);
    string private constant _VERSION = "0.1.0";

    constructor(address _factory) {
        _disableInitializers();
        if (_factory == address(0)) revert ZeroAddress();
        FACTORY = StoryBlocksRegistryFactory(_factory);
    }

    function initialize(address accessControl) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl);
        __ERC721_init("Story Protocol", "SP");
    }

    function version() external pure override returns (string memory) {
        return _VERSION;
    }

    function registerFranchise(
        string calldata name,
        string calldata symbol,
        string calldata description
    ) external returns (uint256, address) {
        address storyBlocksRegistry = FACTORY.createFranchiseBlocks(
            ++_franchiseIds,
            name,
            symbol,
            description
        );
        _storyBlockRegistries[_franchiseIds] = storyBlocksRegistry;
        _safeMint(msg.sender, _franchiseIds);
        emit FranchiseRegistered(msg.sender, _franchiseIds, storyBlocksRegistry);
        return (_franchiseIds, storyBlocksRegistry);
    }

    function storyBlockRegistryForId(
        uint256 franchiseId
    ) public view returns (address) {
        return _storyBlockRegistries[franchiseId];
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

}