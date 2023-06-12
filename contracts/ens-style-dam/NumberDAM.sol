// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./INumberDAM.sol";
import "./BaseDAM.sol";

abstract contract NumberDAM is INumberDAM, BaseDAM {
    mapping(uint256 => mapping(string => uint256)) numbers;


    function setNumber(
        uint256 storyBlockId,
        string calldata key,
        uint256 value
    ) external virtual onlyWriter(storyBlockId) onlyAllowedKey(key) {
        numbers[storyBlockId][key] = value;
        emit NumberChanged(storyBlockId, key, key, value);
    }

    function number(
        uint256 storyBlockId,
        string calldata key
    ) external view virtual override returns (uint256) {
        return numbers[storyBlockId][key];
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override returns (bool) {
        return
            interfaceID == type(INumberDAM).interfaceId ||
            super.supportsInterface(interfaceID);
    }

}