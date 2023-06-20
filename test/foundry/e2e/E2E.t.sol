// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
/*
import '../utils/ProxyHelper.sol';
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/story-blocks/StoryBlocksRegistryFactory.sol";
import "contracts/IStoryBlockAware.sol";
import "contracts/dam/StoryBlockStorage.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract E2ETest is Test, ProxyHelper, IStoryBlockAware, ERC721Holder {
    StoryBlocksRegistryFactory public factory;
    FranchiseRegistry public franchiseRegistry;
    StoryBlockStorage public ipStorage;

    address admin;

    function setUp() public {
        factory = new StoryBlocksRegistryFactory();
        address accessControl = address(new AccessControlSingleton());
        
        FranchiseRegistry impl = new FranchiseRegistry(address(factory));
        franchiseRegistry = FranchiseRegistry(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), accessControl
                )
            )
        );
        ipStorage = new StoryBlockStorage(address(franchiseRegistry), address(franchiseRegistry));
    }

    function test_registerFranchiseCreateStory() public {
        (uint256 franchiseId, address storyBlocksAddress) = franchiseRegistry.registerFranchise(address(this), "Franchise 1", "F1", "Franchise 1 description");
        StoryBlocksRegistry storyBlocks = StoryBlocksRegistry(storyBlocksAddress);
        assertEq(storyBlocks.name(), "Franchise 1");
        assertEq(storyBlocks.symbol(), "F1");
        assertEq(storyBlocks.description(), "Franchise 1 description");
        assertEq(storyBlocks.version(), "0.1.0");
        assertEq(franchiseRegistry.ownerOf(1), address(this));
        uint256 blockId = storyBlocks.mint(address(this), IStoryBlockAware.StoryBlock.STORY);
        ipStorage.writeStoryBlock(franchiseId, blockId, IStoryBlockAware.StoryBlock.STORY, "Story 1", "Story 1 description", "https://story1.com");
        StoryBlockStorage.StoryBlockData memory storyBlock = ipStorage.readStoryBlock(franchiseId, blockId);
        assertEq(storyBlock.name, "Story 1");
        assertEq(storyBlock.description, "Story 1 description");
        assertEq(storyBlock.mediaUrl, "https://story1.com");
        assertEq(uint8(storyBlock.blockType), uint8(IStoryBlockAware.StoryBlock.STORY));

    } 

   
}
*/