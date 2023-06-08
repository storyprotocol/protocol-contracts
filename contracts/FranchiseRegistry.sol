// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IStoryBlockAware } from "./IStoryBlockAware.sol";
import { StoryBlocksRegistryFactory } from "./franchises/StoryBlocksRegistryFactory.sol";
import { AccessControlledUpgradeable } from "./access-control/AccessControlledUpgradeable.sol";
import { UPGRADER_ROLE } from "./access-control/ProtocolRoles.sol";
import { ZeroAddress } from "./errors/General.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract FranchiseRegistry is UUPSUpgradeable, AccessControlledUpgradeable, ERC721Upgradeable, IStoryBlockAware {

    event FranchiseRegistered(address owner, uint256 id, address storyBlocksContract);
    error AlreadyRegistered();

    uint256 _franchiseIds;
    // Franchise id => Collection address
    mapping(uint256 => address) public _storyBlocks;

    StoryBlocksRegistryFactory public immutable FACTORY;
    uint256 public constant PROTOCOL_ROOT_ID = 0;
    address public constant PROTOCOL_ROOT_ADDRESS = address(0);


    constructor(address _factory) {
        _disableInitializers();
        if (_factory == address(0)) revert ZeroAddress("factory");
        FACTORY = StoryBlocksRegistryFactory(_factory);
    }

    function initialize(address accessControl) public initializer {
        __UUPSUpgradeable_init();
        __AccessControlledUpgradeable_init(accessControl);
        __ERC721_init("Story Protocol", "SP");
    }

    function registerFranchise(address to, string calldata name, string calldata symbol, string calldata description) external returns(address) {
        address franchise = FACTORY.createFranchise(name, symbol, description);
        _storyBlocks[++_franchiseIds] = franchise;
        _safeMint(to, _franchiseIds);
        emit FranchiseRegistered(to, _franchiseIds, franchise);
        return franchise;
    }

    function storyBlocksContract(uint256 franchiseId) public view returns(address) {
        return _storyBlocks[franchiseId];
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {
    }

}