// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "contracts/interfaces/modules/royalties/ISplitMain.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MockSplit {
    ISplitMain public immutable splitMain;
    constructor() {
        splitMain = ISplitMain(msg.sender);
    }

    function sendERC20ToMain(ERC20 token, uint256 amount)
        external
        payable
    {
        token.transfer(address(splitMain), amount);
    }
}
