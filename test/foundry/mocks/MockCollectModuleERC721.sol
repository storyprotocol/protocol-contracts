// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.18;

import { ERC721 } from "contracts/modules/collect/nft/ERC721.sol";

contract MockCollectModuleERC721 is ERC721 {

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

}
