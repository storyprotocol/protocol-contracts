// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
//import "forge-std/console.sol";
import { IStoryBlocksRegistry } from "./IStoryBlocksRegistry.sol";
import { LibStoryBlockId } from "./LibStoryBlockId.sol";
import { Unauthorized, ZeroAddress } from "../errors/General.sol";
import { StoryBlockData } from "./data-access-modules/storage/StoryBlockData.sol";
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

    error IdOverBounds();

    /// @custom:storage-location erc7201:story-protocol.story-blocks-registry.storage
    struct StoryBlockRegistryStorage {
        /// @dev storyBlockId => id counter
        mapping(StoryBlock => uint256) ids;
        string description;
        uint256 franchiseId;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.story-blocks-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x13165038cecff7e5e516182f2f44ae706f1efd51262640024578ea7d73b994bd;
    string private constant _VERSION = "0.1.0";

    constructor() {
        _disableInitializers();
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
        StoryBlockRegistryStorage storage $ = _getStoryBlockRegistryStorage();
        $.franchiseId = _franchiseId;
        $.description = _description;
    }

    function _getStoryBlockRegistryStorage()
        private
        pure
        returns (StoryBlockRegistryStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function version() external pure virtual override returns (string memory) {
        return _VERSION;
    }

    function _mintBlock(address to, StoryBlock sb) internal override returns (uint256) {
        uint256 nextId = currentIdFor(sb) + 1;
        if (nextId > LibStoryBlockId._lastId(sb)) revert IdOverBounds();
        StoryBlockRegistryStorage storage $ = _getStoryBlockRegistryStorage();
        $.ids[sb] = nextId;
        _safeMint(to, nextId);
        return nextId;
    }

    function currentIdFor(StoryBlock sb) public view returns (uint256) {
        StoryBlockRegistryStorage storage $ = _getStoryBlockRegistryStorage();
        uint256 currentId = $.ids[sb];
        if (currentId == 0) {
            return LibStoryBlockId._zeroId(sb);
        } else {
            return currentId;
        }
    }

    function description() external view returns (string memory) {
        StoryBlockRegistryStorage storage $ = _getStoryBlockRegistryStorage();
        return $.description;
    }

    function franchiseId() external view returns (uint256) {
        StoryBlockRegistryStorage storage $ = _getStoryBlockRegistryStorage();
        return $.franchiseId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return readStoryBlock(tokenId).mediaUrl;
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

}
