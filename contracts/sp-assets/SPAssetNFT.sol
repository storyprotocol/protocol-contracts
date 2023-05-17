// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { ISPAssetNFT } from "./ISPAssetNFT.sol";

contract SPAssetNFT is ISPAssetNFT, OwnableUpgradeable, ERC721Upgradeable {

    string public constant override version = "0.1.0";

    constructor() {
        _disableInitializers();
    }

    function initialize(string calldata name, string calldata symbol) public initializer {
        __Ownable_init();
        __ERC721_init(name, symbol);
        // _setBaseURI("https://api.splinterlands.io/asset/");
    }

    function mint(address to, uint256 id) external onlyOwner {
        _safeMint(to, id);
    }

    uint256[50] private __gap;
}
