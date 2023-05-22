// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ISPFranchiseNFT } from "./ISPFranchiseNFT.sol";
import { IStoryBlockAware } from "../IStoryBlockAware.sol";
import { Unauthorized, ZeroAddress } from "../errors/General.sol";
import { ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "hardhat/console.sol";

contract SPFranchiseNFT is ISPFranchiseNFT, ERC721Upgradeable {

    event StoryBlockMinted(address indexed to, StoryBlock indexed sb, uint256 indexed tokenId);

    error IdOverBounds();

    mapping(StoryBlock => uint256) private _ids;
    string public description;

    string private constant _version = "0.1.0";
    uint256 private constant _ID_RANGE = 10**12;
    uint256 private constant _ZERO_ID_STORY = 0;
    uint256 private constant _ZERO_ID_CHARACTER = _ID_RANGE + _ZERO_ID_STORY;
    uint256 private constant _ZERO_ID_ART = _ID_RANGE + _ZERO_ID_CHARACTER;
    uint256 private constant _ZERO_ID_GROUP = _ID_RANGE + _ZERO_ID_ART;
    uint256 private constant _ZERO_ID_LOCATION = _ID_RANGE + _ZERO_ID_GROUP;
    uint256 private constant _LAST_ID = _ID_RANGE + _ZERO_ID_LOCATION;

    constructor() {
        _disableInitializers();
    }

    function version() external pure virtual override returns (string memory) {
        return _version;
    }

    function initialize(
        string calldata _name,
        string calldata _symbol,
        string calldata _description
    ) public initializer {
        __ERC721_init(_name, _symbol);
        description = _description; 
        // _setBaseURI("https://api.splinterlands.io/asset/");
    }

    function mint(address to, StoryBlock sb) external {
        uint256 nextId = currentIdFor(sb) + 1;
        if (nextId > lastId(sb)) revert IdOverBounds();
        _ids[sb] = nextId;
        _safeMint(to, nextId);
        emit StoryBlockMinted(to, sb, nextId);
    }

    function currentIdFor(StoryBlock sb) public view returns (uint256) {
        if (_ids[sb] == 0) {
            return zeroId(sb);
        } else {
            unchecked {
                return _ids[sb];   
            }
        }
    }

    function zeroId(StoryBlock sb) public pure returns (uint256) {
        if (sb == StoryBlock.STORY) return _ZERO_ID_STORY;
        if (sb == StoryBlock.CHARACTER) return _ZERO_ID_CHARACTER;
        if (sb == StoryBlock.ART) return _ZERO_ID_ART;
        if (sb == StoryBlock.GROUP) return _ZERO_ID_GROUP;
        if (sb == StoryBlock.LOCATION) return _ZERO_ID_LOCATION;
        revert InvalidStoryBlock(sb);
    }

    function lastId(StoryBlock sb) public pure returns (uint256) {
        if (sb == StoryBlock.STORY) return _ZERO_ID_CHARACTER;
        if (sb == StoryBlock.CHARACTER) return _ZERO_ID_ART;
        if (sb == StoryBlock.ART) return _ZERO_ID_GROUP;
        if (sb == StoryBlock.GROUP) return _ZERO_ID_LOCATION;
        if (sb == StoryBlock.LOCATION) return _LAST_ID;
        revert InvalidStoryBlock(sb);
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
            interfaceId == type(ISPFranchiseNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    uint256[48] private __gap;
}
