// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { IPAssetRegistry } from "../../contracts/ip-assets/IPAssetRegistry.sol";
import { IPAssetRegistryFactory } from "../../contracts/ip-assets/IPAssetRegistryFactory.sol";
import { IPAsset } from "../../contracts/IPAsset.sol";
import { LibIPAssetId } from "../../contracts/ip-assets/LibIPAssetId.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { IERC1967 } from "@openzeppelin/contracts/interfaces/IERC1967.sol";
import { MockIPAssetEventEmitter } from "./mocks/MockIPAssetEventEmitter.sol";
import { MockCollectNFT } from "./mocks/MockCollectNFT.sol";
import { MockCollectModule } from "./mocks/MockCollectModule.sol";
import { MockLicensingModule } from "./mocks/MockLicensingModule.sol";
import "forge-std/Test.sol";

contract IPAssetRegistryTest is Test {
    using stdStorage for StdStorage;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    error IdOverBounds();
    error InvalidBlockType();

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    address owner = address(this);
    address mintee = address(1);
    address mintee2 = address(2);
    address mockFranchiseRegistry = address(0x7474);
    address mockLicenseModule;

    uint256 private constant _ID_RANGE = 10**12;
    uint256 private constant _FIRST_ID_STORY = 1;
    uint256 private constant _FIRST_ID_CHARACTER = _ID_RANGE + _FIRST_ID_STORY;
    uint256 private constant _FIRST_ID_ART = _ID_RANGE + _FIRST_ID_CHARACTER;
    uint256 private constant _FIRST_ID_GROUP = _ID_RANGE + _FIRST_ID_ART;
    uint256 private constant _FIRST_ID_LOCATION = _ID_RANGE + _FIRST_ID_GROUP;
    uint256 private constant _LAST_ID = _ID_RANGE + _FIRST_ID_LOCATION;

    function setUp() public {
        factory = new IPAssetRegistryFactory();
        address mockEventEmitter = address(new MockIPAssetEventEmitter());
        mockLicenseModule = address(new MockLicensingModule());
        address mockCollectModule = address(new MockCollectModule(mockFranchiseRegistry, address(new MockCollectNFT())));

        factory.upgradeFranchises(address(new IPAssetRegistry(mockEventEmitter, mockLicenseModule, mockFranchiseRegistry, mockCollectModule)));
        ipAssetRegistry = IPAssetRegistry(factory.createFranchiseIPAssets(1, "name", "symbol", "description"));
    }

    function test_setUp() public {
        assertEq(ipAssetRegistry.name(), "name");
        assertEq(ipAssetRegistry.symbol(), "symbol");
        assertEq(ipAssetRegistry.description(), "description");
        assertEq(ipAssetRegistry.version(), "0.1.0");
    }

    function test_mintIdAssignment() public {
        uint8 firstIPAssetType = uint8(IPAsset.STORY);
        uint8 lastIPAssetTypeId = uint8(IPAsset.ITEM);
        for(uint8 i = firstIPAssetType; i < lastIPAssetTypeId; i++) {
            IPAsset sb = IPAsset(i);
            uint256 zero = LibIPAssetId._zeroId(sb);
            assertEq(ipAssetRegistry.currentIdFor(sb), zero, "starts with zero");
            vm.prank(mockFranchiseRegistry);
            uint256 blockId1 = ipAssetRegistry.createIPAsset(sb, "name", "description", "mediaUrl", mintee, 0);
            assertEq(blockId1, zero + 1, "returned blockId is incremented by one");
            assertEq(ipAssetRegistry.currentIdFor(sb), zero + 1, "mint increments currentIdFor by one");
            vm.prank(mockFranchiseRegistry);
            uint256 blockId2 = ipAssetRegistry.createIPAsset(sb, "name2", "description2", "mediaUrl2", mintee, 0);
            assertEq(blockId2, zero + 2, "returned blockId is incremented by one again");
            assertEq(ipAssetRegistry.currentIdFor(sb), zero + 2, "2 mint increments currentIdFor by one again");
        }
        
    }

    function test_mintStoryOwnership() public {
        uint8 firstIPAssetType = uint8(IPAsset.STORY);
        uint8 lastIPAssetTypeId = uint8(IPAsset.ITEM);
        for(uint8 i = firstIPAssetType; i < lastIPAssetTypeId; i++) {
            IPAsset sb = IPAsset(i);
            uint256 loopBalance = ipAssetRegistry.balanceOf(mintee);
            assertEq(loopBalance, (i - 1) * 2, "balance is zero for block type");
            vm.prank(mockFranchiseRegistry);
            uint256 blockId1 = ipAssetRegistry.createIPAsset(sb, "name", "description", "mediaUrl", mintee, 0);
            assertEq(ipAssetRegistry.balanceOf(mintee), loopBalance + 1, "balance is incremented by one");
            assertEq(ipAssetRegistry.ownerOf(blockId1), mintee);
            vm.prank(mockFranchiseRegistry);
            uint256 blockId2 = ipAssetRegistry.createIPAsset(sb, "name", "description", "mediaUrl", mintee, 0);
            assertEq(ipAssetRegistry.balanceOf(mintee), loopBalance + 2, "balance is incremented by one again");
            assertEq(ipAssetRegistry.ownerOf(blockId2), mintee);
        }
    }

    function test_revertMintUnknownIPAsset() public {
        vm.startPrank(mockFranchiseRegistry);
        vm.expectRevert(InvalidBlockType.selector);
        ipAssetRegistry.createIPAsset(IPAsset.UNDEFINED, "name", "description", "mediaUrl", mintee, 0);
    }

    function test_IPAssetCreationData() public {
        vm.prank(mockFranchiseRegistry);
        uint256 blockId = ipAssetRegistry.createIPAsset(IPAsset.STORY, "name", "description", "mediaUrl", mintee, 0);
        IPAssetRegistry.IPAssetData memory data = ipAssetRegistry.readIPAsset(blockId);
        assertEq(uint8(data.blockType), uint8(IPAsset.STORY));
        assertEq(data.name, "name");
        assertEq(data.description, "description");
        assertEq(data.mediaUrl, "mediaUrl");
    }

    function test_emptyIPAssetRead() public {
        IPAssetRegistry.IPAssetData memory data = ipAssetRegistry.readIPAsset(12312313);
        assertEq(uint8(data.blockType), uint8(IPAsset.UNDEFINED));
        assertEq(data.name, "");
        assertEq(data.description, "");
        assertEq(data.mediaUrl, "");
    }

    function test_tokenUriReturnsMediaURL() public {
        vm.prank(mockFranchiseRegistry);
        uint256 blockId = ipAssetRegistry.createIPAsset(IPAsset.STORY, "name", "description", "https://mediaUrl.xyz", mintee, 0);
        assertEq(ipAssetRegistry.tokenURI(blockId), "https://mediaUrl.xyz");    
    }

}
