// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/franchises/SPFranchiseNFTFactory.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC1967 } from "@openzeppelin/contracts/interfaces/IERC1967.sol";


contract SPFranchiseNFTFactoryTest is Test {
    SPFranchiseNFTFactory public factory;
    SPFranchiseNFT public franchise;
    address owner = address(this);

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);

    function setUp() public {
        factory = new SPFranchiseNFTFactory();
        franchise = SPFranchiseNFT(factory.createFranchise("name", "symbol", "description"));
    }

    function test_setUp() public {
        assertEq(franchise.name(), "name");
        assertEq(franchise.symbol(), "symbol");
        assertEq(franchise.description(), "description");
        assertEq(franchise.version(), "0.1.0");
        assertEq(franchise.owner(), address(factory));

    }


}
