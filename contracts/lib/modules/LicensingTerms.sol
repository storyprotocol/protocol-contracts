// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

library TermCategories {
    string constant FORMAT_CATEGORIES = "FORMAT_CATEGORIES";
}

/// @dev must be < 32 bytes long, or they will blow up at some point
/// see https://docs.openzeppelin.com/contracts/4.x/api/utils#ShortStrings
library TermIds {
    string constant SHARE_ALIKE = "SHARE_ALIKE";
}

library TermData {
    // ShareAlike is so universal it could be enshrined in
    // the protocol itself
    struct ShareAlike {
        bool enabled;
    }

}