// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IVersioned } from "../utils/IVersioned.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

interface IIPOrg is
    IVersioned,
    IERC165Upgradeable
{

    function owner() external view returns (address);

}
