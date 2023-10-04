// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IVersioned } from "../utils/IVersioned.sol";
import { IIPAssetDataManager } from "./storage/IIPAssetDataManager.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC5218 } from "../modules/licensing/IERC5218.sol";
import { IPAsset } from "contracts/IPAsset.sol";

interface IIPAssetRegistry is
    IVersioned,
    IERC165Upgradeable,
    IERC5218,
    IIPAssetDataManager
{
    function franchiseId() external view returns (uint256);

    function createIpAsset(
        IPAsset sb,
        string calldata name,
        string calldata _description,
        string calldata mediaUrl,
        address to,
        uint256 parentIpAssetId
    ) external returns (uint256);
}
