// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IVersioned } from "../utils/IVersioned.sol";
import { IStoryBlockStorage } from './data-access-modules/storage/IStoryBlockStorage.sol';
import { IGroupDAM } from "./data-access-modules/group/IGroupDAM.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";


interface IStoryBlocksRegistry is 
    IVersioned,
    IERC165Upgradeable,
    IERC721Upgradeable,
    IStoryBlockStorage,
    IGroupDAM
    { }
