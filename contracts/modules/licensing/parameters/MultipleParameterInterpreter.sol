// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IParameterInterpreter } from "./IParameterInterpreter.sol";
import { EmptyArray } from "contracts/errors/General.sol";

contract MultipleParameterInterpreter is IParameterInterpreter {
    
    IParameterInterpreter[] public interpreters;

    constructor(IParameterInterpreter[] memory _interpreters) {
        setInterpreters(_interpreters);
    }

    function setInterpreters(IParameterInterpreter[] memory _interpreters) public {
        if (_interpreters.length == 0) revert EmptyArray();
        interpreters = _interpreters;
    }

    function encodeParams() external returns(bytes memory) {
        bytes[] memory encodedParams = new bytes[](interpreters.length);
        for (uint256 i = 0; i < interpreters.length; i++) {
            encodedParams[i] = interpreters[i].encodeParams();
        }
        return abi.encode(encodedParams);
    }

}