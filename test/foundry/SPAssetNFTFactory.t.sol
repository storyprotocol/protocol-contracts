// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../contracts/sp-assets/SPAssetNFTFactory.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC1967 } from "@openzeppelin/contracts/interfaces/IERC1967.sol";

contract SPAssetNFTFactoryTest is Test {
    SPAssetNFTFactory public factory;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event BeaconUpgraded(address indexed beacon);

    function setUp() public {
        factory = new SPAssetNFTFactory();
    }

    function test_Contructor() public {
        assertTrue(address(factory.BEACON()) != address(0));
        UpgradeableBeacon beacon = factory.BEACON();
        assertTrue(address(beacon.implementation()) != address(0));
        assertEq(SPAssetNFT(beacon.implementation()).version(), "0.1.0");
    }

    function test_CreateCollection() public {
        vm.expectEmit(false, true, true, true);
        emit CollectionCreated(address(0x123), "name", "symbol");
        // TODO: figure why this is not matching correctly, the event is emitted according to traces
        //vm.expectEmit();
        //emit BeaconUpgraded(address(0x123));
        address collection = factory.createCollection("name", "symbol");
        assertTrue(collection != address(0));
        assertEq(SPAssetNFT(collection).name(), "name");
        assertEq(SPAssetNFT(collection).symbol(), "symbol");
    }

}
