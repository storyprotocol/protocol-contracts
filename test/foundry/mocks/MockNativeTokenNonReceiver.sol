// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

error Revert();

contract MockNativeTokenNonReceiver {

    receive() external payable {
        revert Revert();
    }
}

