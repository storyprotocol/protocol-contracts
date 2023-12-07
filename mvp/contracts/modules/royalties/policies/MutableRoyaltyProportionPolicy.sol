// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { IRoyaltyPolicy } from "contracts/interfaces/modules/royalties/policies/IRoyaltyPolicy.sol";
import { RoyaltyNFT } from "contracts/modules/royalties/RoyaltyNFT.sol";
import { Royalties } from "contracts/lib/modules/Royalties.sol";

contract MutableRoyaltyProportionPolicy is IRoyaltyPolicy {
    RoyaltyNFT public immutable royaltyNFT;

    constructor(address royaltyNft_) {
        royaltyNFT = RoyaltyNFT(royaltyNft_);
    }

    function initPolicy(address, bytes calldata) override external {}

    function updateDistribution(address sourceAccount_, bytes calldata data_) override external {
        Royalties.ProportionData memory propData = abi.decode(data_, (Royalties.ProportionData));
        uint256 tokenId = royaltyNFT.toTokenId(sourceAccount_);
        if (!royaltyNFT.exists(tokenId)) {
            royaltyNFT.mint(sourceAccount_, propData.accounts, propData.percentAllocations);
        } else {
            for (uint256 i = 0; i < propData.accounts.length; ++i) {
                royaltyNFT.safeTransferFrom(
                    sourceAccount_,
                    propData.accounts[i],
                    tokenId,
                    propData.percentAllocations[i],
                    ""
                );
            }
        }
    }

    function distribute(address account_, address token_) override external {
        royaltyNFT.distributeFunds(account_, token_);
    }
}
