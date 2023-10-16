// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";
import { IPAssetGroup } from "../../contracts/ip-assets/IPAssetGroup.sol";
import { IPAssetController } from "contracts/IPAssetController.sol";
import { IPAsset } from "../../contracts/lib/IPAsset.sol";
import { MockIPAssetEventEmitter } from "./mocks/MockIPAssetEventEmitter.sol";
import { MockCollectNFT } from "./mocks/MockCollectNFT.sol";
import { MockCollectModule } from "./mocks/MockCollectModule.sol";
import { MockLicensingModule } from "./mocks/MockLicensingModule.sol";
import { MockIPAssetController } from "./mocks/MockIPAssetController.sol";
import "forge-std/Test.sol";

contract IPAssetGroupTest is Test {
    using stdStorage for StdStorage;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    error IdOverBounds();
    error InvalidBlockType();

    IPAssetController public controller;
    IPAssetGroup public ipAssetGroup;
    address owner = address(this);
    address mintee = address(1);
    address mintee2 = address(2);
    address mockLicenseModule;

    uint256 internal ipAssetGroupOwnerPk = 0xa11ce;
    address payable internal ipAssetGroupOwner = payable(vm.addr(ipAssetGroupOwnerPk));

    function setUp() public {
        controller = new IPAssetController();

        address mockEventEmitter = address(new MockIPAssetEventEmitter());
        mockLicenseModule = address(new MockLicensingModule());

        address mockCollectModule = address(new MockCollectModule(address(controller), address(new MockCollectNFT())));

        IPAsset.RegisterIPAssetGroupParams memory params = IPAsset.RegisterIPAssetGroupParams(
            "name",
            "symbol",
            "description",
            "uri",
            mockLicenseModule,
            mockCollectModule
        );
        vm.prank(ipAssetGroupOwner);
        (uint256 ipAssetGroupId, address ipAssetGroupAddr) = controller.registerIPAssetGroup(params);
        ipAssetGroup = IPAssetGroup(ipAssetGroupAddr);
    }

    function test_setUp() public {
        assertEq(ipAssetGroup.name(), "name");
        assertEq(ipAssetGroup.symbol(), "symbol");
        assertEq(ipAssetGroup.description(), "description");
        assertEq(ipAssetGroup.version(), "0.1.0");
    }

    function test_mintIdAssignment() public {
        uint8 firstIPAssetType = uint8(IPAsset.IPAssetType.STORY);
        uint8 lastIPAssetTypeId = uint8(IPAsset.IPAssetType.ITEM);
        for(uint8 i = firstIPAssetType; i < lastIPAssetTypeId; i++) {
            IPAsset.IPAssetType ipAsset = IPAsset.IPAssetType(i);
            uint256 zero = IPAsset._zeroId(ipAsset);
            assertEq(ipAssetGroup.currentIdFor(ipAsset), zero, "starts with zero");
            vm.prank(address(controller));
            uint256 blockId1 = ipAssetGroup.createIpAsset(ipAsset, "name", "description", "mediaUrl", mintee, 0, "");
            assertEq(blockId1, zero + 1, "returned blockId is incremented by one");
            assertEq(ipAssetGroup.currentIdFor(ipAsset), zero + 1, "mint increments currentIdFor by one");
            vm.prank(address(controller));
            uint256 blockId2 = ipAssetGroup.createIpAsset(ipAsset, "name2", "description2", "mediaUrl2", mintee, 0, "");
            assertEq(blockId2, zero + 2, "returned blockId is incremented by one again");
            assertEq(ipAssetGroup.currentIdFor(ipAsset), zero + 2, "2 mint increments currentIdFor by one again");
        }
        
    }

    function test_mintStoryOwnership() public {
        uint8 firstIPAssetType = uint8(IPAsset.IPAssetType.STORY);
        uint8 lastIPAssetTypeId = uint8(IPAsset.IPAssetType.ITEM);
        for(uint8 i = firstIPAssetType; i < lastIPAssetTypeId; i++) {
            IPAsset.IPAssetType ipAsset = IPAsset.IPAssetType(i);
            uint256 loopBalance = ipAssetGroup.balanceOf(mintee);
            assertEq(loopBalance, (i - 1) * 2, "balance is zero for block type");
            vm.prank(address(controller));
            uint256 blockId1 = ipAssetGroup.createIpAsset(ipAsset, "name", "description", "mediaUrl", mintee, 0, "");
            assertEq(ipAssetGroup.balanceOf(mintee), loopBalance + 1, "balance is incremented by one");
            assertEq(ipAssetGroup.ownerOf(blockId1), mintee);
            vm.prank(address(controller));
            uint256 blockId2 = ipAssetGroup.createIpAsset(ipAsset, "name", "description", "mediaUrl", mintee, 0, "");
            assertEq(ipAssetGroup.balanceOf(mintee), loopBalance + 2, "balance is incremented by one again");
            assertEq(ipAssetGroup.ownerOf(blockId2), mintee);
        }
    }

    function test_revertMintUnknownIPAsset() public {
        vm.prank(address(controller));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.IPAsset_InvalidType.selector, IPAsset.IPAssetType.UNDEFINED)
        );
        ipAssetGroup.createIpAsset(IPAsset.IPAssetType.UNDEFINED, "name", "description", "mediaUrl", mintee, 0, "");
    }

    function test_IPAssetCreationData() public {
        vm.prank(address(controller));
        uint256 blockId = ipAssetGroup.createIpAsset(IPAsset.IPAssetType.STORY, "name", "description", "mediaUrl", mintee, 0, "");
    }

    function test_emptyIPAssetRead() public {
        IPAssetGroup.IPAssetData memory data = ipAssetGroup.readIPAsset(12312313);
        assertEq(uint8(data.blockType), uint8(IPAsset.IPAssetType.UNDEFINED));
        assertEq(data.name, "");
        assertEq(data.description, "");
        assertEq(data.mediaUrl, "");
    }

    function test_tokenUriReturnsMediaURL() public {
        vm.prank(address(controller));
        uint256 blockId = ipAssetGroup.createIpAsset(IPAsset.IPAssetType.STORY, "name", "description", "https://mediaUrl.xyz", mintee, 0, "");
        assertEq(ipAssetGroup.tokenURI(blockId), "https://mediaUrl.xyz");    
    }

}
