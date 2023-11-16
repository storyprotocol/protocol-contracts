// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

library ShortStringOps {
    using ShortStrings for *;

    function _equal(
        ShortString a,
        ShortString b
    ) internal pure returns (bool) {
        return ShortString.unwrap(a) == ShortString.unwrap(b);
    }

    function _equal(
        ShortString a,
        string memory b
    ) internal pure returns (bool) {
        return _equal(a, b.toShortString());
    }

    function _equal(
        string memory a,
        ShortString b
    ) internal pure returns (bool) {
        return _equal(a.toShortString(), b);
    }

    function _equal(
        bytes32 a,
        ShortString b
    ) internal pure returns (bool) {
        return a == ShortString.unwrap(b);
    }

    function _equal(
        string memory a,
        bytes32 b
    ) internal pure returns (bool) {
        return _equal(a, ShortString.wrap(b));
    }

    function _equal(
        bytes32 a,
        string memory b
    ) internal pure returns (bool) {
        return _equal(ShortString.wrap(a), b);
    }
}
