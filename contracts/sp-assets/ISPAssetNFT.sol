// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IVersioned } from "../utils/IVersioned.sol";

/**
 * @title 
 * @author 
 * @notice WARNING: Non upgradeable contract, but part of the Beacon
 */
interface ISPAssetNFT is IVersioned, IERC721Upgradeable {
    function mint(address to, uint256 id) external;
}
