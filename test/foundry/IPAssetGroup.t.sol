// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";
import { IPAssetOrg } from "../../contracts/ip-assets/IPAssetOrg.sol";
import { IPAssetOrgFactory } from "contracts/IPAssetOrgFactory.sol";
import { IPAsset } from "../../contracts/lib/IPAsset.sol";
import { IPAssetRegistry } from "../../contracts/IPAssetRegistry.sol";
import { MockIPAssetEventEmitter } from "./mocks/MockIPAssetEventEmitter.sol";
import { MockCollectNFT } from "./mocks/MockCollectNFT.sol";
import { MockCollectModule } from "./mocks/MockCollectModule.sol";
import { MockLicensingModule } from "./mocks/MockLicensingModule.sol";
import { MockIPAssetOrgFactory } from "./mocks/MockIPAssetOrgFactory.sol";
import "forge-std/Test.sol";

contract IPAssetOrgTest is Test {
    using stdStorage for StdStorage;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    error IdOverBounds();
    error InvalidBlockType();

    IPAssetRegistry public registry;
    IPAssetOrgFactory public ipAssetOrgFactory;
    IPAssetOrg public ipAssetOrg;
    address owner = address(this);
    address mintee = address(1);
    address mintee2 = address(2);
    address mockLicenseModule;

    uint256 internal ipAssetOrgOwnerPk = 0xa11ce;
    address payable internal ipAssetOrgOwner = payable(vm.addr(ipAssetOrgOwnerPk));

    function setUp() public {
        registry = new IPAssetRegistry();
        ipAssetOrgFactory = new IPAssetOrgFactory();

        address mockEventEmitter = address(new MockIPAssetEventEmitter());
        mockLicenseModule = address(new MockLicensingModule());

        address mockCollectModule = address(new MockCollectModule(address(registry), address(new MockCollectNFT())));


        IPAsset.RegisterIPAssetOrgParams memory ipAssetOrgParams = IPAsset.RegisterIPAssetOrgParams(
            address(registry),
            "name",
            "symbol",
            "description",
            "uri",
            mockLicenseModule,
            mockCollectModule
        );
        vm.prank(ipAssetOrgOwner);
        address ipAssetOrgAddr;
        ipAssetOrgAddr = ipAssetOrgFactory.registerIPAssetOrg(ipAssetOrgParams);
        ipAssetOrg = IPAssetOrg(ipAssetOrgAddr);
    }

    function test_setUp() public {
        assertEq(ipAssetOrg.name(), "name");
        assertEq(ipAssetOrg.symbol(), "symbol");
        assertEq(ipAssetOrg.version(), "0.1.0");
    }

    function test_mintIdAssignment() public {
        uint8 firstIPAssetType = uint8(IPAsset.IPAssetType.STORY);
        uint8 lastIPAssetTypeId = uint8(IPAsset.IPAssetType.ITEM);
        for(uint8 i = firstIPAssetType; i < lastIPAssetTypeId; i++) {
            IPAsset.IPAssetType ipAsset = IPAsset.IPAssetType(i);
            uint256 zero = IPAsset._zeroId(ipAsset);
            assertEq(ipAssetOrg.currentIdFor(ipAsset), zero, "starts with zero");
            vm.prank(address(ipAssetOrgFactory));
            (, uint256 blockId1) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
                ipAssetType: ipAsset,
                name: "name",
                description: "description",
                mediaUrl: "mediaUrl",
                to: mintee,
                parentIpAssetOrgId: 0,
                collectData: ""
            }));
            assertEq(blockId1, zero + 1, "returned blockId is incremented by one");
            assertEq(ipAssetOrg.currentIdFor(ipAsset), zero + 1, "mint increments currentIdFor by one");
            vm.prank(address(ipAssetOrgFactory));
            (, uint256 blockId2) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
                ipAssetType: ipAsset,
                name: "name2",
                description: "description2",
                mediaUrl: "mediaUrl2",
                to: mintee,
                parentIpAssetOrgId: 0,
                collectData: ""
            }));
            assertEq(blockId2, zero + 2, "returned blockId is incremented by one again");
            assertEq(ipAssetOrg.currentIdFor(ipAsset), zero + 2, "2 mint increments currentIdFor by one again");
        }
        
    }

    function test_mintStoryOwnership() public {
        uint8 firstIPAssetType = uint8(IPAsset.IPAssetType.STORY);
        uint8 lastIPAssetTypeId = uint8(IPAsset.IPAssetType.ITEM);
        for(uint8 i = firstIPAssetType; i < lastIPAssetTypeId; i++) {
            IPAsset.IPAssetType ipAsset = IPAsset.IPAssetType(i);
            uint256 loopBalance = ipAssetOrg.balanceOf(mintee);
            assertEq(loopBalance, (i - 1) * 2, "balance is zero for block type");
            vm.prank(address(ipAssetOrgFactory));
            (, uint256 blockId1) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
                ipAssetType: ipAsset,
                name: "name",
                description: "description",
                mediaUrl: "mediaUrl",
                to: mintee,
                parentIpAssetOrgId: 0,
                collectData: ""
            }));
            assertEq(ipAssetOrg.balanceOf(mintee), loopBalance + 1, "balance is incremented by one");
            assertEq(ipAssetOrg.ownerOf(blockId1), mintee);
            vm.prank(address(ipAssetOrgFactory));
            (, uint256 blockId2) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
                ipAssetType: ipAsset,
                name: "name",
                description: "description",
                mediaUrl: "mediaUrl",
                to: mintee,
                parentIpAssetOrgId: 0,
                collectData: ""
            }));
            assertEq(ipAssetOrg.balanceOf(mintee), loopBalance + 2, "balance is incremented by one again");
            assertEq(ipAssetOrg.ownerOf(blockId2), mintee);
        }
    }

    function test_revertMintUnknownIPAsset() public {
        vm.prank(address(ipAssetOrgFactory));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.IPAsset_InvalidType.selector, IPAsset.IPAssetType.UNDEFINED)
        );
        ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
            ipAssetType: IPAsset.IPAssetType.UNDEFINED,
            name: "name",
            description: "description",
            mediaUrl: "mediaUrl",
            to: mintee,
            parentIpAssetOrgId: 0,
            collectData: ""
        }));
    }

    function test_IPAssetCreationData() public {
        vm.prank(address(ipAssetOrgFactory));
        (, uint256 blockId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
            ipAssetType: IPAsset.IPAssetType.STORY,
            name: "name",
            description: "description",
            mediaUrl: "mediaUrl",
            to: mintee,
            parentIpAssetOrgId: 0,
            collectData: ""
        }));
    }

    function test_emptyIPAssetRead() public {
        IPAssetOrg.IPAssetData memory data = ipAssetOrg.readIPAsset(12312313);
        assertEq(uint8(data.blockType), uint8(IPAsset.IPAssetType.UNDEFINED));
        assertEq(data.name, "");
        assertEq(data.description, "");
        assertEq(data.mediaUrl, "");
    }

    function test_tokenUriReturnsMediaURL() public {
        vm.prank(address(ipAssetOrgFactory));
        (, uint256 blockId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
            ipAssetType: IPAsset.IPAssetType.STORY,
            name: "name",
            description: "description",
            mediaUrl: "https://mediaUrl.xyz",
            to: mintee,
            parentIpAssetOrgId: 0,
            collectData: ""
        }));
        assertEq(ipAssetOrg.tokenURI(blockId), "https://mediaUrl.xyz");    
    }

}
