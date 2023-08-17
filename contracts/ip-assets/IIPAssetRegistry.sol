// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IVersioned } from "../utils/IVersioned.sol";
import { IIPAssetDataManager } from './data-access-modules/storage/IIPAssetDataManager.sol';
import { IGroupDAM } from "./data-access-modules/group/IGroupDAM.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC5218 } from "../modules/licensing/IERC5218.sol";

interface IIPAssetRegistry is 
    IVersioned,
    IERC165Upgradeable,
    IERC5218,
    IIPAssetDataManager,
    IGroupDAM
    { 
    function franchiseId() external view returns (uint256);
    }
