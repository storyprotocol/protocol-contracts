// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ICollectNFTEventsAndErrors } from "./ICollectNFTEventsAndErrors.sol";

/// @title CollectNFT Interface
interface ICollectNFT is IERC721, ICollectNFTEventsAndErrors {

    function initialize(uint256 ipAssetId, bytes calldata data) external;

    function collect(address collector) external;

}
