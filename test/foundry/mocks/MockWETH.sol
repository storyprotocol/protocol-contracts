// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.18;

import {WETH} from "solmate/src/tokens/WETH.sol";

contract MockWETH is WETH {

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}
