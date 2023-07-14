// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { BaseLinkProcessor } from "./BaseLinkProcessor.sol";
import { ILinkingModule } from "../ILinkingModule.sol";

contract PermissionlessLinkProcessor is BaseLinkProcessor {

    constructor(address linkingModule) BaseLinkProcessor(linkingModule) {}

    function _processLink(ILinkingModule.LinkParams memory, bytes calldata, address) internal virtual override {
        // do nothing
    }
}