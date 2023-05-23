// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { SPFranchiseNFT } from "../../contracts/franchises/SPFranchiseNFT.sol";
import { SPFranchiseNFTFactory } from "../../contracts/franchises/SPFranchiseNFTFactory.sol";
import { IStoryBlockAware } from "../../contracts/IStoryBlockAware.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC1967 } from "@openzeppelin/contracts/interfaces/IERC1967.sol";
import "forge-std/Test.sol";

contract SPFranchiseNFTTest is Test, IStoryBlockAware {
    using stdStorage for StdStorage;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    error IdOverBounds();

    SPFranchiseNFTFactory public factory;
    SPFranchiseNFT public franchise;
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
        factory = new SPFranchiseNFTFactory();
        franchise = SPFranchiseNFT(factory.createFranchise("name", "symbol", "description"));
    }

    function test_setUp() public {
        assertEq(franchise.name(), "name");
        assertEq(franchise.symbol(), "symbol");
        assertEq(franchise.description(), "description");
        assertEq(franchise.version(), "0.1.0");
    }

    function test_zeroIds() public {
        assertEq(franchise.zeroId(StoryBlock.STORY), 0);
        assertEq(franchise.zeroId(StoryBlock.CHARACTER), 10**12);
        assertEq(franchise.zeroId(StoryBlock.ART), 2*10**12);
        assertEq(franchise.zeroId(StoryBlock.GROUP), 3*10**12);
        assertEq(franchise.zeroId(StoryBlock.LOCATION), 4*10**12);
    }

    function test_lastIds() public {
        assertEq(franchise.lastId(StoryBlock.STORY), 10**12);
        assertEq(franchise.lastId(StoryBlock.CHARACTER), 2*10**12);
        assertEq(franchise.lastId(StoryBlock.ART), 3*10**12);
        assertEq(franchise.lastId(StoryBlock.GROUP), 4*10**12);
        assertEq(franchise.lastId(StoryBlock.LOCATION), 5*10**12);
    }

    function test_mintStory() public {
        assertEq(franchise.balanceOf(mintee), 0);
        assertEq(franchise.currentIdFor(StoryBlock.STORY), _FIRST_ID_STORY - 1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), mintee, _FIRST_ID_STORY);
        franchise.mint(mintee, StoryBlock.STORY);
        assertEq(franchise.currentIdFor(StoryBlock.STORY), _FIRST_ID_STORY);
        assertEq(franchise.balanceOf(mintee), 1);
        assertEq(franchise.ownerOf(_FIRST_ID_STORY), mintee);
        franchise.mint(mintee, StoryBlock.STORY);
        assertEq(franchise.currentIdFor(StoryBlock.STORY), _FIRST_ID_STORY + 1);
        assertEq(franchise.balanceOf(mintee), 2);
        assertEq(franchise.ownerOf(_FIRST_ID_STORY + 1), mintee);
    }

    function TODO_test_revertMintOverLastStory() private {
        /*
        uint256 slot = stdstore
            .target(address(franchise))
            .sig(franchise.currentIdFor.selector)
            .find();
        console.log(slot);
        
        bytes32 loc = bytes32(slot);
        bytes32 mockedCurrentTokenId = bytes32(abi.encode(franchise.lastId(StoryBlock.STORY)));
        vm.store(address(franchise), loc, mockedCurrentTokenId);
        vm.expectRevert(IdOverBounds.selector);
        franchise.mint(mintee, StoryBlock.STORY);
        */
    }

    function test_mintCharacter() public {
        assertEq(franchise.balanceOf(mintee), 0);
        assertEq(franchise.currentIdFor(StoryBlock.CHARACTER), _FIRST_ID_CHARACTER - 1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), mintee, _FIRST_ID_CHARACTER);
        franchise.mint(mintee, StoryBlock.CHARACTER);
        assertEq(franchise.currentIdFor(StoryBlock.CHARACTER), _FIRST_ID_CHARACTER);
        assertEq(franchise.balanceOf(mintee), 1);
        assertEq(franchise.ownerOf(_FIRST_ID_CHARACTER), mintee);
        franchise.mint(mintee, StoryBlock.CHARACTER);
        assertEq(franchise.currentIdFor(StoryBlock.CHARACTER), _FIRST_ID_CHARACTER + 1);
        assertEq(franchise.balanceOf(mintee), 2);
        assertEq(franchise.ownerOf(_FIRST_ID_CHARACTER + 1), mintee);
    }

    function test_mintArt() public {
        assertEq(franchise.balanceOf(mintee), 0);
        assertEq(franchise.currentIdFor(StoryBlock.ART), _FIRST_ID_ART - 1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), mintee, _FIRST_ID_ART);
        franchise.mint(mintee, StoryBlock.ART);
        assertEq(franchise.currentIdFor(StoryBlock.ART), _FIRST_ID_ART);
        assertEq(franchise.balanceOf(mintee), 1);
        assertEq(franchise.ownerOf(_FIRST_ID_ART), mintee);
        franchise.mint(mintee, StoryBlock.ART);
        assertEq(franchise.currentIdFor(StoryBlock.ART), _FIRST_ID_ART + 1);
        assertEq(franchise.balanceOf(mintee), 2);
        assertEq(franchise.ownerOf(_FIRST_ID_ART + 1), mintee);
    }

    function test_mintGroup() public {
        assertEq(franchise.balanceOf(mintee), 0);
        assertEq(franchise.currentIdFor(StoryBlock.GROUP), _FIRST_ID_GROUP - 1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), mintee, _FIRST_ID_GROUP);
        franchise.mint(mintee, StoryBlock.GROUP);
        assertEq(franchise.currentIdFor(StoryBlock.GROUP), _FIRST_ID_GROUP);
        assertEq(franchise.balanceOf(mintee), 1);
        assertEq(franchise.ownerOf(_FIRST_ID_GROUP), mintee);
        franchise.mint(mintee, StoryBlock.GROUP);
        assertEq(franchise.currentIdFor(StoryBlock.GROUP), _FIRST_ID_GROUP + 1);
        assertEq(franchise.balanceOf(mintee), 2);
        assertEq(franchise.ownerOf(_FIRST_ID_GROUP + 1), mintee);
    }

    function test_mintLocation() public {
        assertEq(franchise.balanceOf(mintee), 0);
        assertEq(franchise.currentIdFor(StoryBlock.LOCATION), _FIRST_ID_LOCATION - 1);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), mintee, _FIRST_ID_LOCATION);
        franchise.mint(mintee, StoryBlock.LOCATION);
        assertEq(franchise.currentIdFor(StoryBlock.LOCATION), _FIRST_ID_LOCATION);
        assertEq(franchise.balanceOf(mintee), 1);
        assertEq(franchise.ownerOf(_FIRST_ID_LOCATION), mintee);
        franchise.mint(mintee, StoryBlock.LOCATION);
        assertEq(franchise.currentIdFor(StoryBlock.LOCATION), _FIRST_ID_LOCATION + 1);
        assertEq(franchise.balanceOf(mintee), 2);
        assertEq(franchise.ownerOf(_FIRST_ID_LOCATION + 1), mintee);
    }
    
}
