import { IPAsset } from "contracts/lib/IPAsset.sol";

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface IIPAssetRegistry {

    event IPAssetRegistered(
        uint256 ipAssetId_,
        address owner_,
        address ipAssetOrg_
    );

    event OrgTransferred(
        uint256 indexed ipAssetId_,
        address indexed owner_
    );

    event OwnerTransferred(
        uint256 indexed ipAssetId_,
        address indexed owner_
    );

}
