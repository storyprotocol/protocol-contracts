// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/ip-assets/IPAssetRegistryFactory.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC1967 } from "@openzeppelin/contracts/interfaces/IERC1967.sol";

contract IPAssetRegistryv2 is IPAssetRegistry {
    function version() virtual override external pure returns (string memory) {
        return "2.0.0";
    }
}

contract IPAssetRegistryFactoryTest is Test {

    event FranchiseCreated(address indexed collection, string name, string indexed symbol);
    event FranchisessUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);

    address notOwner = address(0x123);
    IPAssetRegistryFactory public factory;

    function setUp() public {
        factory = new IPAssetRegistryFactory();
    }

    function test_Contructor() public {
        assertTrue(address(factory.BEACON()) != address(0));
        UpgradeableBeacon beacon = factory.BEACON();
        assertTrue(address(beacon.implementation()) != address(0));
        assertEq(IPAssetRegistry(beacon.implementation()).version(), "0.1.0");
    }

    function test_CreateFranchiseBlocks() public {
        vm.expectEmit(false, true, true, true);
        emit FranchiseCreated(address(0x123), "name", "symbol");
        // TODO: figure why this is not matching correctly, the event is emitted according to traces
        // vm.expectEmit();
        // emit BeaconUpgraded(address(0x123));
        address collection = factory.createFranchiseBlocks(1, "name", "symbol", "description");
        assertTrue(collection != address(0));
        assertEq(IPAssetRegistry(collection).name(), "name");
        assertEq(IPAssetRegistry(collection).symbol(), "symbol");
    }

    function test_UpgradeCollections() public {
        IPAssetRegistryv2 newImplementation = new IPAssetRegistryv2();
        //vm.expectEmit(true, true, true, true);
        //emit CollectionsUpgraded(address(newImplementation), "2.0.0");
        factory.upgradeFranchises(address(newImplementation));
        UpgradeableBeacon beacon = factory.BEACON();
        assertEq(IPAssetRegistry(beacon.implementation()).version(), "2.0.0");
    }

    function test_revertIfNotOwnerUpgrades() public {
        IPAssetRegistryv2 newImplementation = new IPAssetRegistryv2();
        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.upgradeFranchises(address(newImplementation));
    }

}
