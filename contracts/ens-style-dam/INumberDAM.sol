// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface INumberDAM {
    event NumberChanged(
        uint256 indexed storyBlockId,
        string indexed indexedKey,
        string key,
        uint256 value
    );

    function number(
        uint256 storyBlockId,
        string calldata key
    ) external view returns (uint256);
}