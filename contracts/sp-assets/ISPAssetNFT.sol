// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IVersioned } from "../utils/IVersioned.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title 
 * @author 
 * @notice WARNING: Non upgradeable contract, but part of the Beacon
 */
interface ISPAssetNFT is IVersioned, IERC165Upgradeable, IERC721Upgradeable {
    function mint(address to, uint256 id) external;
}
