// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

interface ITextDAM {
    event TextChanged(
        uint256 indexed storyBlockId,
        string indexed indexedKey,
        string key,
        string value
    );


    function text(
        uint256 storyBlockId,
        string calldata key
    ) external view returns (string memory);
}