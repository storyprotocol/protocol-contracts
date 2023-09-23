// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MockThrowingERC20 is ERC20 {

    enum TransferBehavior {
        Fail,
        ReturnInvalidABI,
        ReturnFalse
    }

    TransferBehavior public behavior;

    constructor(string memory name, string memory symbol, uint8 decimals, TransferBehavior behavior_) ERC20(name, symbol, decimals) {
        behavior = behavior_;
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

     function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (behavior == TransferBehavior.Fail) {
            revert();
        }

        if (behavior == TransferBehavior.ReturnInvalidABI) {
            assembly {
                mstore(0x0, 0x1)
                return(0x0, 1)
            }
        }

        if (behavior == TransferBehavior.ReturnFalse) {
            return false;
        }

        return super.transferFrom(sender, recipient, amount);
    }

}
