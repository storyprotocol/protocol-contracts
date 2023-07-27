// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.13;

interface IVersioned {

    function version() external view returns (string memory);

}