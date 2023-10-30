// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IVersioned } from "./utils/IVersioned.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

interface IIPAssetOrgFactory is IVersioned {

    event IPAssetOrgRegistered(
        address owner_,
        address ipAssetOrg_,
        string name_,
        string symbol_,
        string tokenURI_
    );

    function registerIPAssetOrg(IPAsset.RegisterIPAssetOrgParams calldata params_) external returns(address);

    function isIpAssetOrg(address ipAssetOrg_) external view returns (bool);
}
