// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "contracts/IStoryBlockAware.sol"; 

abstract contract StoryBlockMinter is IStoryBlockAware {
    function _mintBlock(address to, StoryBlock sb) internal virtual returns (uint256);
}