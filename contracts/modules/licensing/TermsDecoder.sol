// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;




contract TermsDecoder {

    function decodeString(bytes memory data_) public pure returns (string memory) {
        return abi.decode(data_, (string));
    }

    function decodeStringArray(bytes memory data_) public pure returns (string[] memory) {
        return abi.decode(data_, (string[]));
    }

    function decodeUint256(bytes memory data_) public pure returns (uint256) {
        return abi.decode(data_, (uint256));
    }

    function decodeUint256Array(bytes memory data_) public pure returns (uint256[] memory) {
        return abi.decode(data_, (uint256[]));
    }

    function decodeAddress(bytes memory data_) public pure returns (address) {
        return abi.decode(data_, (address));
    }

    function decodeAddressArray(bytes memory data_) public pure returns (address[] memory) {
        return abi.decode(data_, (address[]));
    }

    function decodeBytes32(bytes memory data_) public pure returns (bytes32) {
        return abi.decode(data_, (bytes32));
    }

    function decodeBytes32Array(bytes memory data_) public pure returns (bytes32[] memory) {
        return abi.decode(data_, (bytes32[]));
    }

    function decodeBytesArray(bytes memory data_) public pure returns (bytes[] memory) {
        return abi.decode(data_, (bytes[]));
    }

}