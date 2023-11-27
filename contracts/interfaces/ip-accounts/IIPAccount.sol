// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC1155Receiver } from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC6551Account } from "./IERC6551Account.sol";

interface IIPAccount is IERC6551Account, IERC721Receiver, IERC1155Receiver {
    function safeTransferFrom(
        address nftContract_,
        address from_,
        address to_,
        uint256 tokenId_
    ) external;

    function sendRoyaltyForDistribution(
        address distributor_,
        address token_
    ) external;
}
