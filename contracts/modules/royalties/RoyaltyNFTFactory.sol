// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { RoyaltyNFT } from "./RoyaltyNFT.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract RoyaltyNFTFactory {
    event CreateRoyaltyNFT(RoyaltyNFT indexed royaltyNft);

    address public immutable royaltyNft;

    constructor(address _splitMain) {
        royaltyNft = address(new RoyaltyNFT(_splitMain));
    }

    function createRoyaltyNft(
        bytes32 salt
    ) external returns (RoyaltyNFT rn) {
        rn = RoyaltyNFT(Clones.cloneDeterministic(royaltyNft, salt));
        emit CreateRoyaltyNFT(rn);
    }
}
