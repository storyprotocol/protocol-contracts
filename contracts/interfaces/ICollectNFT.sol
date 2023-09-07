// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ICollectNFTEventsAndErrors } from "./ICollectNFTEventsAndErrors.sol";
import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";

/// @title CollectNFT Interface
interface ICollectNFT is IERC721, ICollectNFTEventsAndErrors {

    function totalSupply() external view returns (uint256);

    function initialize(InitCollectNFTParams calldata initParams) external;

    function collect(address collector, bytes calldata data) external;

}
