// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import {IRoyaltyProportionPolicy} from "./IRoyaltyProportionPolicy.sol";
import { RoyaltyNFT } from "contracts/modules/royalties/RoyaltyNFT.sol";


contract MutableRoyaltyProportionPolicy is IRoyaltyProportionPolicy {
    RoyaltyNFT public immutable royaltyNFT;

    constructor(address _royaltyNft) {
        royaltyNFT = RoyaltyNFT(_royaltyNft);
    }

    function initPolicy(address, bytes calldata) override external {}

    function updateDistribution(address sourceAccount, bytes calldata data) override external {
        ProportionData memory propData = abi.decode(data, (ProportionData));
        uint256 tokenId = royaltyNFT.toTokenId(sourceAccount);
        if (!royaltyNFT.exists(tokenId)) {
            royaltyNFT.mint(sourceAccount, propData.accounts, propData.percentAllocations);
        } else {
            for (uint256 i = 0; i < propData.accounts.length; ++i) {
                royaltyNFT.safeTransferFrom(
                    sourceAccount,
                    propData.accounts[i],
                    tokenId,
                    propData.percentAllocations[i],
                    ""
                );
            }
        }
    }

    function distribute(address account, address token) override external {
        royaltyNFT.distributeFunds(account, token);
    }
}
