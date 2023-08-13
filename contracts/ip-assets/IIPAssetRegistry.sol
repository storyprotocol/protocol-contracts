// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IVersioned } from "../utils/IVersioned.sol";
import { IIPAssetDataManager } from './storage/IIPAssetDataManager.sol';
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import { IPAsset } from "contracts/IPAsset.sol";

interface IIPAssetRegistry is 
    IVersioned,
    IERC165Upgradeable,
    IERC721Upgradeable,
    IIPAssetDataManager
    {
        function createIPAsset(
            IPAsset sb,
            string calldata name,
            string calldata _description,
            string calldata mediaUrl
        ) external returns (uint256);
        function franchiseId() external view returns (uint256);
    }
