// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVersioned {
    function version() external pure returns (string memory);
}
