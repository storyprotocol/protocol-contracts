// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ISPAssetNFT } from "./ISPAssetNFT.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

contract SPAssetNFT is ISPAssetNFT, OwnableUpgradeable, ERC721Upgradeable {
    
    string public constant _version = "0.1.0";

    constructor() {
        _disableInitializers();
    }

    function version() virtual override external pure returns (string memory) {
        return _version;
    }

    function initialize(string calldata name, string calldata symbol) public initializer {
        __Ownable_init();
        __ERC721_init(name, symbol);
        // _setBaseURI("https://api.splinterlands.io/asset/");
    }

    function mint(address to, uint256 id) external onlyOwner {
        _safeMint(to, id);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(ISPAssetNFT).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}
