// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { StoryBlocksRegistry } from "../../contracts/story-blocks/StoryBlocksRegistry.sol";
import { StoryBlocksRegistryFactory } from "../../contracts/story-blocks/StoryBlocksRegistryFactory.sol";
import { StoryBlock } from "../../contracts/StoryBlock.sol";
import { LibStoryBlockId } from "../../contracts/story-blocks/LibStoryBlockId.sol";
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
    error InvalidBlockType();

    StoryBlocksRegistryFactory public factory;
    StoryBlocksRegistry public storyBlocks;
    address owner = address(this);
    address mintee = address(1);
    address mintee2 = address(2);

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

    function test_mintIdAssignment() public {
        uint8 firstStoryBlockType = uint8(StoryBlock.STORY);
        uint8 lastStoryBlockTypeId = uint8(StoryBlock.ITEM);
        for(uint8 i = firstStoryBlockType; i < lastStoryBlockTypeId; i++) {
            StoryBlock sb = StoryBlock(i);
            uint256 zero = LibStoryBlockId._zeroId(sb);
            assertEq(storyBlocks.currentIdFor(sb), zero, "starts with zero");
            vm.prank(mintee);
            uint256 blockId1 = storyBlocks.createStoryBlock(sb, "name", "description", "mediaUrl");
            assertEq(blockId1, zero + 1, "returned blockId is incremented by one");
            assertEq(storyBlocks.currentIdFor(sb), zero + 1, "mint increments currentIdFor by one");
            vm.prank(mintee);
            uint256 blockId2 = storyBlocks.createStoryBlock(sb, "name2", "description2", "mediaUrl2");
            assertEq(blockId2, zero + 2, "returned blockId is incremented by one again");
            assertEq(storyBlocks.currentIdFor(sb), zero + 2, "2 mint increments currentIdFor by one again");
        }
        
    }

    function test_mintStoryOwnership() public {
        uint8 firstStoryBlockType = uint8(StoryBlock.STORY);
        uint8 lastStoryBlockTypeId = uint8(StoryBlock.ITEM);
        for(uint8 i = firstStoryBlockType; i < lastStoryBlockTypeId; i++) {
            StoryBlock sb = StoryBlock(i);
            uint256 loopBalance = storyBlocks.balanceOf(mintee);
            assertEq(loopBalance, (i - 1) * 2, "balance is zero for block type");
            vm.prank(mintee);
            uint256 blockId1 = storyBlocks.createStoryBlock(sb, "name", "description", "mediaUrl");
            assertEq(storyBlocks.balanceOf(mintee), loopBalance + 1, "balance is incremented by one");
            assertEq(storyBlocks.ownerOf(blockId1), mintee);
            vm.prank(mintee);
            uint256 blockId2 = storyBlocks.createStoryBlock(sb, "name", "description", "mediaUrl");
            assertEq(storyBlocks.balanceOf(mintee), loopBalance + 2, "balance is incremented by one again");
            assertEq(storyBlocks.ownerOf(blockId2), mintee);
        }
    }

    function test_revertMintUnknownStoryBlock() public {
        vm.startPrank(mintee);
        vm.expectRevert(InvalidBlockType.selector);
        storyBlocks.createStoryBlock(StoryBlock.UNDEFINED, "name", "description", "mediaUrl");
    }

    function test_storyBlockCreationData() public {
        vm.prank(mintee);
        uint256 blockId = storyBlocks.createStoryBlock(StoryBlock.STORY, "name", "description", "mediaUrl");
        StoryBlocksRegistry.StoryBlockData memory data = storyBlocks.readStoryBlock(blockId);
        assertEq(uint8(data.blockType), uint8(StoryBlock.STORY));
        assertEq(data.name, "name");
        assertEq(data.description, "description");
        assertEq(data.mediaUrl, "mediaUrl");
    }

    function test_emptyStoryBlockRead() public {
        StoryBlocksRegistry.StoryBlockData memory data = storyBlocks.readStoryBlock(12312313);
        assertEq(uint8(data.blockType), uint8(StoryBlock.UNDEFINED));
        assertEq(data.name, "");
        assertEq(data.description, "");
        assertEq(data.mediaUrl, "");
    }

    function test_tokenUriReturnsMediaURL() public {
        vm.prank(mintee);
        uint256 blockId = storyBlocks.createStoryBlock(StoryBlock.STORY, "name", "description", "https://mediaUrl.xyz");
        assertEq(storyBlocks.tokenURI(blockId), "https://mediaUrl.xyz");    
    }

}