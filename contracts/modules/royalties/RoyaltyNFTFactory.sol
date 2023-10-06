// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { RoyaltyNFT } from "./RoyaltyNFT.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract RoyaltyNFTFactory {
    event CreateRoyaltyNFT(RoyaltyNFT indexed royaltyNft);

    address public immutable royaltyNft;

    constructor(address splitMain_) {
        royaltyNft = address(new RoyaltyNFT(splitMain_));
    }

    function createRoyaltyNft(
        bytes32 salt_
    ) external returns (RoyaltyNFT rn) {
        rn = RoyaltyNFT(Clones.cloneDeterministic(royaltyNft, salt_));
        emit CreateRoyaltyNFT(rn);
    }
}
