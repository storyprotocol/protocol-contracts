// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";

contract MockIPOrg is IIPOrg {

    address private _owner;

    constructor(address owner_) {
        _owner = owner_;
    }

    function ownerOf(uint256 id) external view returns (address) {
        return _owner;
    }

    function burn(uint256 id) external override(IIPOrg) {}

    function contractURI() external pure returns (string memory) {
        return "";
    }

    function transferFrom(address from, address to, uint256 id) external {}

    function mint(address owner_) external override(IIPOrg) returns (uint256 id) {}

    function owner() external view override(IIPOrg) returns (address) {
        return _owner;
    }
}
