// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IVersioned } from "./utils/IVersioned.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

interface IIPOrgFactory is IVersioned {

    event IPOrgRegistered(
        address owner_,
        address ipAssetOrg_,
        string name_,
        string symbol_,
        string tokenURI_
    );

    function registerIPOrg(IPAsset.RegisterIPOrgParams calldata params_) external returns(address);

    function isIpOrg(address ipAssetOrg_) external view returns (bool);
}
