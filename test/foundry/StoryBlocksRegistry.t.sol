// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { StoryBlocksRegistry } from "../../contracts/story-blocks/StoryBlocksRegistry.sol";
import { StoryBlocksRegistryFactory } from "../../contracts/story-blocks/StoryBlocksRegistryFactory.sol";
import { StoryBlock } from "../../contracts/StoryBlock.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC1967 } from "@openzeppelin/contracts/interfaces/IERC1967.sol";
import "forge-std/Test.sol";

contract StoryBlocksRegistryTest is Test {
    using stdStorage for StdStorage;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    error IdOverBounds();

    StoryBlocksRegistryFactory public factory;
    StoryBlocksRegistry public storyBlocks;
    address owner = address(this);
    address mintee = address(1);

    uint256 private constant _ID_RANGE = 10**12;
    uint256 private constant _FIRST_ID_STORY = 1;
    uint256 private constant _FIRST_ID_CHARACTER = _ID_RANGE + _FIRST_ID_STORY;
    uint256 private constant _FIRST_ID_ART = _ID_RANGE + _FIRST_ID_CHARACTER;
    uint256 private constant _FIRST_ID_GROUP = _ID_RANGE + _FIRST_ID_ART;
    uint256 private constant _FIRST_ID_LOCATION = _ID_RANGE + _FIRST_ID_GROUP;
    uint256 private constant _LAST_ID = _ID_RANGE + _FIRST_ID_LOCATION;

    function setUp() public {
        factory = new StoryBlocksRegistryFactory();
        storyBlocks = StoryBlocksRegistry(factory.createFranchiseBlocks(1, "name", "symbol", "description"));
    }

    function test_setUp() public {
        assertEq(storyBlocks.name(), "name");
        assertEq(storyBlocks.symbol(), "symbol");
        assertEq(storyBlocks.description(), "description");
        assertEq(storyBlocks.version(), "0.1.0");
    }

    function test_mintStory() public {
        assertEq(storyBlocks.balanceOf(mintee), 0);
        assertEq(storyBlocks.currentIdFor(StoryBlock.STORY), _FIRST_ID_STORY - 1);
        // vm.expectEmit(true, true, true, true);
        // emit Transfer(address(0), mintee, _FIRST_ID_STORY);
        vm.prank(mintee);
        uint256 blockId1 = storyBlocks.createStory("name", "description", "mediaUrl");
        assertEq(blockId1, _FIRST_ID_STORY);
        assertEq(storyBlocks.currentIdFor(StoryBlock.STORY), _FIRST_ID_STORY);
        assertEq(storyBlocks.balanceOf(mintee), 1);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_STORY), mintee);
        vm.prank(mintee);
        uint256 blockId2 = storyBlocks.createStory("name2", "description2", "mediaUrl2");
        assertEq(blockId2, _FIRST_ID_STORY + 1);
        assertEq(storyBlocks.currentIdFor(StoryBlock.STORY), _FIRST_ID_STORY + 1);
        assertEq(storyBlocks.balanceOf(mintee), 2);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_STORY + 1), mintee);
    }

    function TODO_test_revertMintOverLastStory() private {
        /*
        uint256 slot = stdstore
            .target(address(storyBlocks))
            .sig(storyBlocks.currentIdFor.selector)
            .find();
        console.log(slot);
        
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(storyBlocks.lastId(StoryBlock.STORY)));
        vm.store(address(storyBlocks), loc, mockedCurrentTokenId);
        vm.expectRevert(IdOverBounds.selector);
        storyBlocks.mint(mintee, StoryBlock.STORY);
        */
    }

    function test_mintCharacter() public {
        assertEq(storyBlocks.balanceOf(mintee), 0);
        assertEq(storyBlocks.currentIdFor(StoryBlock.CHARACTER), _FIRST_ID_CHARACTER - 1);
        // vm.expectEmit(true, true, true, true);
        // emit Transfer(address(0), mintee, _FIRST_ID_CHARACTER);
        vm.prank(mintee);
        uint256 blockId1 = storyBlocks.createCharacter("name", "description", "mediaUrl");
        assertEq(blockId1, _FIRST_ID_CHARACTER);
        assertEq(storyBlocks.currentIdFor(StoryBlock.CHARACTER), _FIRST_ID_CHARACTER);
        assertEq(storyBlocks.balanceOf(mintee), 1);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_CHARACTER), mintee);
        vm.prank(mintee);
        uint256 blockId2 = storyBlocks.createArt("name2", "description2", "mediaUrl2");
        assertEq(blockId2, _FIRST_ID_CHARACTER + 1);
        assertEq(storyBlocks.currentIdFor(StoryBlock.CHARACTER), _FIRST_ID_CHARACTER + 1);
        assertEq(storyBlocks.balanceOf(mintee), 2);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_CHARACTER + 1), mintee);
    }

    function test_mintArt() public {
        assertEq(storyBlocks.balanceOf(mintee), 0);
        assertEq(storyBlocks.currentIdFor(StoryBlock.ART), _FIRST_ID_ART - 1);
        // vm.expectEmit(true, true, true, true);
        // emit Transfer(address(0), mintee, _FIRST_ID_ART);
        vm.prank(mintee);
        uint256 blockId1 = storyBlocks.createArt("name", "description", "mediaUrl");
        assertEq(blockId1, _FIRST_ID_ART);
        assertEq(storyBlocks.currentIdFor(StoryBlock.ART), _FIRST_ID_ART);
        assertEq(storyBlocks.balanceOf(mintee), 1);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_ART), mintee);
        vm.prank(mintee);
        uint256 blockId2 = storyBlocks.createArt("name2", "description2", "mediaUrl2");
        assertEq(blockId2, _FIRST_ID_ART + 1);
        assertEq(storyBlocks.currentIdFor(StoryBlock.ART), _FIRST_ID_ART + 1);
        assertEq(storyBlocks.balanceOf(mintee), 2);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_ART + 1), mintee);
    }

    function test_mintGroup() public {
        assertEq(storyBlocks.balanceOf(mintee), 0);
        assertEq(storyBlocks.currentIdFor(StoryBlock.GROUP), _FIRST_ID_GROUP - 1);
        // vm.expectEmit(true, true, true, true);
        // emit Transfer(address(0), mintee, _FIRST_ID_GROUP);
        uint256[] memory linked = new uint256[](1);
        vm.prank(mintee);
        uint256 blockId1 = storyBlocks.createGroup("name", "description", "mediaUrl", StoryBlock.STORY, linked);
        assertEq(blockId1, _FIRST_ID_GROUP);
        assertEq(storyBlocks.currentIdFor(StoryBlock.GROUP), _FIRST_ID_GROUP);
        assertEq(storyBlocks.balanceOf(mintee), 1);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_GROUP), mintee);
        vm.prank(mintee);
        uint256 blockId2 = storyBlocks.createGroup("name2", "description2", "mediaUrl2", StoryBlock.CHARACTER, linked);
        assertEq(blockId2, _FIRST_ID_GROUP + 1);
        assertEq(storyBlocks.currentIdFor(StoryBlock.GROUP), _FIRST_ID_GROUP + 1);
        assertEq(storyBlocks.balanceOf(mintee), 2);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_GROUP + 1), mintee);
    }

    function test_mintLocation() public {
        assertEq(storyBlocks.balanceOf(mintee), 0);
        assertEq(storyBlocks.currentIdFor(StoryBlock.LOCATION), _FIRST_ID_LOCATION - 1);
        // vm.expectEmit(true, true, true, true);
        // emit Transfer(address(0), mintee, _FIRST_ID_LOCATION);
        vm.prank(mintee);
        uint256 blockId1 = storyBlocks.createLocation("name", "description", "mediaUrl");
        assertEq(blockId1, _FIRST_ID_LOCATION);
        assertEq(storyBlocks.currentIdFor(StoryBlock.LOCATION), _FIRST_ID_LOCATION);
        assertEq(storyBlocks.balanceOf(mintee), 1);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_LOCATION), mintee);
        vm.prank(mintee);
        uint256 blockId2 = storyBlocks.createLocation("name2", "description2", "mediaUrl2");
        assertEq(blockId2, _FIRST_ID_LOCATION + 1);
        assertEq(storyBlocks.currentIdFor(StoryBlock.LOCATION), _FIRST_ID_LOCATION + 1);
        assertEq(storyBlocks.balanceOf(mintee), 2);
        assertEq(storyBlocks.ownerOf(_FIRST_ID_LOCATION + 1), mintee);
    }
    
}