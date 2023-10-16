// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IVersioned } from "../utils/IVersioned.sol";
import { IIPAssetGroupDataManager } from "./storage/IIPAssetGroupDataManager.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC5218 } from "../modules/licensing/IERC5218.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

interface IIPAssetGroup is
    IVersioned,
    IERC165Upgradeable,
    IERC5218,
    IIPAssetGroupDataManager
{
    function franchiseId() external view returns (uint256);

    function createIpAsset(
        IPAsset.IPAssetType ipAsset_,
        string calldata name_,
        string calldata description_,
        string calldata mediaUrl_,
        address to_,
        uint256 parentIpAssetId_
    ) external returns (uint256);
}
