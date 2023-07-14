// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { ILinkProcessor } from "./ILinkProcessor.sol";
import { ZeroAddress } from "contracts/errors/General.sol";
import { ILinkingModule } from "../ILinkingModule.sol";

abstract contract BaseLinkProcessor is ILinkProcessor {
    
    address internal immutable _LINKING_MODULE;
    error OnlyLinkingModule();

    constructor(address _linkingModule) {
        if(_linkingModule != address(0)) revert ZeroAddress();
        _LINKING_MODULE = _linkingModule;
    }

    function processLink(ILinkingModule.LinkParams memory params, bytes calldata data, address linker) external override {
        if(msg.sender != _LINKING_MODULE) revert OnlyLinkingModule();
        _processLink(params, data, linker);
    }

    function _processLink(ILinkingModule.LinkParams memory params, bytes calldata data, address linker) internal virtual;    

    function supportsInterface(
        bytes4 interfaceId
    ) external pure override returns (bool) {
        return interfaceId == type(ILinkProcessor).interfaceId;
    }

}