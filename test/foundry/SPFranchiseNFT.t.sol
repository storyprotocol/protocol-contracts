// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/franchises/SPFranchiseNFTFactory.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC1967 } from "@openzeppelin/contracts/interfaces/IERC1967.sol";

contract SPFranchiseNFTv2 is SPFranchiseNFT {
    function version() virtual override external pure returns (string memory) {
        return "2.0.0";
    }
}

contract SPFranchiseNFTFactoryTest is Test {
    SPFranchiseNFTFactory public factory;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);

    function setUp() public {
        factory = new SPFranchiseNFTFactory();
    }


}
