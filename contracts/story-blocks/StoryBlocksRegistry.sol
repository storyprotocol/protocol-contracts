// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
//import "forge-std/console.sol";
import { IStoryBlocksRegistry } from "./IStoryBlocksRegistry.sol";
import { LibStoryBlockId } from "./LibStoryBlockId.sol";
import { Unauthorized, ZeroAddress } from "../errors/General.sol";
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
    /// @dev storyBlockId => id counter
    mapping(StoryBlock => uint256) private _ids;
    string public description;
    uint256 public franchiseId;

    string private constant _VERSION = "0.1.0";

    constructor() {
        _disableInitializers();
    }

    function version() external pure virtual override returns (string memory) {
        return _VERSION;
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

    function _mintBlock(address to, StoryBlock sb) internal override returns (uint256) {
        // console.log("mint block", uint8(sb));
        uint256 nextId = currentIdFor(sb) + 1;
        // console.log("nextId", nextId);
        if (nextId > LibStoryBlockId._lastId(sb)) revert IdOverBounds();
        _ids[sb] = nextId;
        // console.log("saved", _ids[sb]);
        _safeMint(to, nextId);
        emit StoryBlockMinted(to, sb, nextId);
        return nextId;
    }

    function currentIdFor(StoryBlock sb) public view returns (uint256) {
        uint256 currentId = _ids[sb];
        if (currentId == 0) {
            return LibStoryBlockId._zeroId(sb);
        } else {
            return currentId;
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
