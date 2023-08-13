// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
//import "forge-std/console.sol";
import { IIPAssetRegistry } from "./IIPAssetRegistry.sol";
import { LibIPAssetId } from "./LibIPAssetId.sol";
import { Unauthorized, ZeroAmount, ZeroAddress } from "../errors/General.sol";
import { IPAsset } from "contracts/IPAsset.sol";
import { IIPAssetEventEmitter } from "./events/IIPAssetEventEmitter.sol";
import { IIPAssetDataManager } from "./storage/IIPAssetDataManager.sol";
import { IPAssetDataManager } from "./storage/IPAssetDataManager.sol";
import { ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { MulticallUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

contract IPAssetRegistry is
    IIPAssetRegistry,
    IPAssetDataManager,
    ERC721Upgradeable,
    MulticallUpgradeable
{

    error IdOverBounds();

    /// @custom:storage-location erc7201:story-protocol.ip-assets-registry.storage
    struct IPAssetRegistryStorage {
        /// @dev IPAssetId => id counter
        mapping(IPAsset => uint256) ids;
        string description;
        uint256 franchiseId;
    }

    IIPAssetEventEmitter public immutable EVENT_EMITTER;
    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.ip-assets-registry.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x1a0b8fa444ff575656111a4368b8e6a743b70cbf31ffb9ee2c7afe1983f0e378;
    string private constant _VERSION = "0.1.0";

    constructor(address _eventEmitter) {
        if (_eventEmitter == address(0)) revert ZeroAddress();
        EVENT_EMITTER = IIPAssetEventEmitter(_eventEmitter);
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
        if (_franchiseId == 0) revert ZeroAmount();
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        $.franchiseId = _franchiseId;
        $.description = _description;
    }

    function _getIPAssetRegistryStorage()
        private
        pure
        returns (IPAssetRegistryStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    function version() external pure virtual override returns (string memory) {
        return _VERSION;
    }

    function createIPAsset(
        IPAsset sb,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl
    ) external virtual override returns (uint256) {
        if (sb == IPAsset.UNDEFINED) revert InvalidBlockType();
        uint256 sbId = _mintBlock(msg.sender, sb);
        _writeIPAsset(sbId, name, _description, mediaUrl);
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        EVENT_EMITTER.emitIPAssetCreation($.franchiseId, sbId);
        return sbId;
    }

    function _mintBlock(address to, IPAsset sb) private returns (uint256) {
        uint256 nextId = currentIdFor(sb) + 1;
        if (nextId > LibIPAssetId._lastId(sb)) revert IdOverBounds();
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        $.ids[sb] = nextId;
        _safeMint(to, nextId);
        return nextId;
    }

    function currentIdFor(IPAsset sb) public view returns (uint256) {
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        uint256 currentId = $.ids[sb];
        if (currentId == 0) {
            return LibIPAssetId._zeroId(sb);
        } else {
            return currentId;
        }
    }

    function description() external view returns (string memory) {
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        return $.description;
    }

    function franchiseId() external view returns (uint256) {
        IPAssetRegistryStorage storage $ = _getIPAssetRegistryStorage();
        return $.franchiseId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return readIPAsset(tokenId).mediaUrl;
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
            interfaceId == type(IIPAssetRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}
