// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
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

    function mint(address owner_, uint8 type_) external override(IIPOrg) returns (uint256 id) {}

    function owner() external view override(IIPOrg) returns (address) {
        return _owner;
    }

    function ipOrgAssetType(uint256 id_) external pure override(IIPOrg) returns (uint8) {
        return 0;
    }

    function ipAssetId(uint256 id_) external returns (uint256) {
        return 0;
    }
}
