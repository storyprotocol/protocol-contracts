// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IVersioned } from "../utils/IVersioned.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";

interface IIPOrgController is IVersioned {

    event IPOrgRegistered(
        address owner,
        address ipAssetOrg,
        string name,
        string symbol,
        string tokenURI,
        string[] ipAssetTypes
    );

    function registerIpOrg(IPOrgParams.RegisterIPOrgParams calldata params_) external returns(address);

    function isIpOrg(address ipAssetOrg_) external view returns (bool);
}
