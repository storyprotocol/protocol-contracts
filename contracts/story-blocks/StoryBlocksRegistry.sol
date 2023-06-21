// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IStoryBlocksRegistry } from "./IStoryBlocksRegistry.sol";
import { LibStoryBlockId } from "./LibStoryBlockId.sol";
import { Unauthorized, ZeroAddress, NonExistentID } from "../errors/General.sol";
import { StoryBlockStorage } from "./data-access-modules/storage/StoryBlockStorage.sol";
import { StoryBlock } from "contracts/StoryBlock.sol";
import { GroupDAM } from "./data-access-modules/group/GroupDAM.sol";
import { ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

contract StoryBlocksRegistry is
    IStoryBlocksRegistry,
    ERC721Upgradeable,
    MulticallUpgradeable,
    GroupDAM
{
    event StoryBlockMinted(
        address indexed to,
        StoryBlock indexed sb,
        uint256 indexed tokenId
    );

    error IdOverBounds();

    mapping(StoryBlock => uint256) private _ids;
    string public description;
    uint256 public franchiseId;

    string private constant _version = "0.1.0";

    constructor() {
        _disableInitializers();
    }

    function version() external pure virtual override returns (string memory) {
        return _version;
    }

    function initialize(
        uint256 _franchiseId,
        string calldata _name,
        string calldata _symbol,
        string calldata _description
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Multicall_init();
        if (_franchiseId == 0) revert ZeroAddress("franchiseId");
        franchiseId = _franchiseId;
        description = _description;
        // _setBaseURI("https://api.splinterlands.io/asset/");
    }

    function createStoryBlock(
        StoryBlock sb,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl
    ) external returns (uint256) {
        uint256 sbId = _mintBlock(msg.sender, sb);
        _writeStoryBlock(sbId, name, _description, mediaUrl);
        return sbId;
    }

    function editStoryBlock(
        uint256 storyBlockId,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl
    ) external {
        if (!_exists(storyBlockId)) revert NonExistentID(storyBlockId);
        _writeStoryBlock(storyBlockId, name, _description, mediaUrl);
    }

    function _mintBlock(address to, StoryBlock sb) internal override returns (uint256) {
        uint256 nextId = currentIdFor(sb) + 1;
        if (nextId > LibStoryBlockId.lastId(sb)) revert IdOverBounds();
        _ids[sb] = nextId;
        _safeMint(to, nextId);
        emit StoryBlockMinted(to, sb, nextId);
        return nextId;
    }

    function _canWriteStoryBlock(
        uint256 storyBlockId
    ) internal view virtual override returns (bool) {
        return ownerOf(storyBlockId) == msg.sender;
    }

    function currentIdFor(StoryBlock sb) public view returns (uint256) {
        if (_ids[sb] == 0) {
            return LibStoryBlockId.zeroId(sb);
        } else {
            return _ids[sb];
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IStoryBlocksRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    uint256[47] private __gap;
}
