// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IModule } from "./IModule.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";

interface IModule {

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);

    function execute(
        IIPOrg ipOrg_,
        address caller_,
        bytes calldata selfParams_,
        bytes[] calldata preHookParams_,
        bytes[] calldata postHookParams_
    ) external;

    function configure(IIPOrg ipOrg_, address caller_, bytes calldata params_) external;

}