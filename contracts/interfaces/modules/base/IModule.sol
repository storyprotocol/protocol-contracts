// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IModule } from "./IModule.sol";

interface IModule {

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);

    function execute(address caller, bytes calldata selfParams, bytes[] calldata preHooksParams, bytes[] calldata postHooksParams) external;
    function configure(address caller_, bytes calldata params_) external;

}