// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ILinkingModule } from "../ILinkingModule.sol";

interface ILinkProcessor {
    function processLink(ILinkingModule.LinkParams memory params, bytes calldata data, address linker) external;
}