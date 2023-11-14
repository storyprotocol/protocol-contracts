// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

library TermCategories {
    string constant FORMAT_CATEGORIES = "FORMAT_CATEGORIES";
    string constant SHARE_ALIKE = "SHARE_ALIKE";
}

/// @dev must be < 32 bytes long, or they will blow up at some point
/// see https://docs.openzeppelin.com/contracts/4.x/api/utils#ShortStrings
library TermIds {
    string constant NFT_SHARE_ALIKE = "NFT_SHARE_ALIKE";
}

library TermData {
    struct NftShareAlike {
        bool enabled;
    }



}