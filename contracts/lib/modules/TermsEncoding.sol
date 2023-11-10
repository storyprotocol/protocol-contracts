// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

library TermsEncoding {
    
    // ShortString.wrap("MEDIUM_CATEGORIES");
    ShortString constant MEDIUM_CATEGORIES = ShortString.wrap(0x4d454449554d5f43415445474f52494553000000000000000000000000000011);

    function _encode(string[] calldata input) internal pure returns (bytes memory) {
        return abi.encode(input);
    }
}