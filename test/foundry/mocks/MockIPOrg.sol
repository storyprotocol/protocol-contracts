// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";

contract MockIPOrg is IIPOrg {

    address private _owner;

    constructor(address owner_) {
        _owner = owner_;
    }

    function version() external pure override returns (string memory) {
        return "1";
    }

    function supportsInterface(bytes4) external pure override returns (bool) {
        return true;
    }

    function owner() external view override returns (address) {
        return _owner;
    }
}
