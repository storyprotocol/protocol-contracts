// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;


contract BasicTermEncoder {

    function encode(string calldata termData_) public pure returns (bytes memory) {
        return abi.encode(termData_);
    }

    function encode(string[] calldata termData_) public pure returns (bytes memory) {
        return abi.encode(termData_);
    }

    function encode(address termData_) public pure returns (bytes memory) {
        return abi.encode(termData_);
    }

    function encode(address[] calldata termData_) public pure returns (bytes memory) {
        return abi.encode(termData_);
    }

    function encode(uint256 termData_) public pure returns (bytes memory) {
        return abi.encode(termData_);
    }

    function encode(uint256[] calldata termData_) public pure returns (bytes memory) {
        return abi.encode(termData_);
    }

    function encode(bytes[] calldata termData_) public pure returns (bytes memory) {
        return abi.encode(termData_);
    }

    function encode(bytes32 termData_) public pure returns (bytes memory) {
        return abi.encode(termData_);
    }

    function encode(bytes32[] calldata termData_) public pure returns (bytes memory) {
        return abi.encode(termData_);
    }

}