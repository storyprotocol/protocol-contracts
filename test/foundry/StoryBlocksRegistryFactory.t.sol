// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;
/*
import "forge-std/Test.sol";
import "contracts/story-blocks/StoryBlocksRegistryFactory.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC1967 } from "@openzeppelin/contracts/interfaces/IERC1967.sol";

contract StoryBlocksRegistryv2 is StoryBlocksRegistry {
    function version() virtual override external pure returns (string memory) {
        return "2.0.0";
    }
}

contract StoryBlocksRegistryFactoryTest is Test {

    event FranchiseCreated(address indexed collection, string name, string indexed symbol);
    event FranchisessUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);

    address notOwner = address(0x123);
    StoryBlocksRegistryFactory public factory;

    function setUp() public {
        factory = new StoryBlocksRegistryFactory();
    }

    function test_Contructor() public {
        assertTrue(address(factory.BEACON()) != address(0));
        UpgradeableBeacon beacon = factory.BEACON();
        assertTrue(address(beacon.implementation()) != address(0));
        assertEq(StoryBlocksRegistry(beacon.implementation()).version(), "0.1.0");
    }

    function test_CreateFranchiseBlocks() public {
        vm.expectEmit(false, true, true, true);
        emit FranchiseCreated(address(0x123), "name", "symbol");
        // TODO: figure why this is not matching correctly, the event is emitted according to traces
        // vm.expectEmit();
        // emit BeaconUpgraded(address(0x123));
        address collection = factory.createFranchiseBlocks(1, "name", "symbol", "description");
        assertTrue(collection != address(0));
        assertEq(StoryBlocksRegistry(collection).name(), "name");
        assertEq(StoryBlocksRegistry(collection).symbol(), "symbol");
    }

    function test_UpgradeCollections() public {
        StoryBlocksRegistryv2 newImplementation = new StoryBlocksRegistryv2();
        //vm.expectEmit(true, true, true, true);
        //emit CollectionsUpgraded(address(newImplementation), "2.0.0");
        factory.upgradeFranchises(address(newImplementation));
        UpgradeableBeacon beacon = factory.BEACON();
        assertEq(StoryBlocksRegistry(beacon.implementation()).version(), "2.0.0");
    }

    function test_revertIfNotOwnerUpgrades() public {
        StoryBlocksRegistryv2 newImplementation = new StoryBlocksRegistryv2();
        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.upgradeFranchises(address(newImplementation));
    }

}
*/