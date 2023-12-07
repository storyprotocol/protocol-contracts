// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
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
