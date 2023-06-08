// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "./NumberDAM.sol";
import "./TextDAM.sol";

contract CharacterDAM is NumberDAM, TextDAM {
    
    constructor(address _franchiseRegistry, address _storyBlocksRegistry) BaseDAM(_franchiseRegistry, _storyBlocksRegistry) {

    }

    function supportsInterface(
        bytes4 interfaceID
    ) public view virtual override(NumberDAM, TextDAM) returns (bool) {
        return super.supportsInterface(interfaceID);
    }
}