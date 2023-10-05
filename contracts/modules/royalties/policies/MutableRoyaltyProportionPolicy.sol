// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {IRoyaltyProportionPolicy} from "contracts/interfaces/modules/royalties/policies/IRoyaltyProportionPolicy.sol";
import { RoyaltyNFT } from "contracts/modules/royalties/RoyaltyNFT.sol";


contract MutableRoyaltyProportionPolicy is IRoyaltyProportionPolicy {
    RoyaltyNFT public immutable royaltyNFT;

    constructor(address royaltyNft_) {
        royaltyNFT = RoyaltyNFT(royaltyNft_);
    }

    function initPolicy(address, bytes calldata) override external {}

    function updateDistribution(address sourceAccount_, bytes calldata data_) override external {
        ProportionData memory propData = abi.decode(data_, (ProportionData));
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
