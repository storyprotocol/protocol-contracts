// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IVersioned } from "../utils/IVersioned.sol";
import { IIPAssetData } from './data-access-modules/storage/IIPAssetData.sol';
import { IGroupDAM } from "./data-access-modules/group/IGroupDAM.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";


interface IIPAssetRegistry is 
    IVersioned,
    IERC165Upgradeable,
    IERC721Upgradeable,
    IIPAssetData,
    IGroupDAM
    { }
