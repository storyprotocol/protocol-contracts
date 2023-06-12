// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./ITextDAM.sol";
import "./BaseDAM.sol";

abstract contract TextDAM is ITextDAM, BaseDAM {
    mapping(uint256 => mapping(string => string)) texts;


    function setText(
        uint256 storyBlockId,
        string calldata key,
        string calldata value
    ) external virtual onlyWriter(storyBlockId) onlyAllowedKey(key) {
        texts[storyBlockId][key] = value;
        emit TextChanged(storyBlockId, key, key, value);
    }


    function text(
        uint256 storyBlockId,
        string calldata key
    ) external view virtual override returns (string memory) {
        return texts[storyBlockId][key];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns (bool) {
        return
            interfaceID == type(ITextDAM).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}