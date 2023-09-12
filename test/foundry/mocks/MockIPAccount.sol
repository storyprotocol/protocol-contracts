// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "contracts/ip-accounts/IPAccountImpl.sol";

contract MockIPAccount is IPAccountImpl {
    constructor() IPAccountImpl() {
    }

    function foo(bool val) pure external {
        if (!val) {
            revert("false");
        }
    }
}
