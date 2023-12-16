// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract ShortStringPrinter is Script {
    using ShortStrings for *;

    string public input = "Hello World";

    function run() view public {
        console.log(input);
        console.logBytes32(ShortString.unwrap(input.toShortString()));
    }
}
