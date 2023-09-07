// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';
import { IPAsset } from "contracts/IPAsset.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";
import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";
import { MockCollectNFT } from "test/foundry/mocks/MockCollectNFT.sol";
import { BaseERC721Test } from "./BaseERC721Test.sol";
import { ICollectNFTEventsAndErrors } from "contracts/interfaces/ICollectNFTEventsAndErrors.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { ERC721Test } from "./ERC721.t.sol";

contract CollectNFTBaseTest is BaseERC721Test, BaseTest, ICollectNFTEventsAndErrors {

    uint256 ipAssetId;
    ICollectNFT collectNFT;

    modifier createCollectNFT(address ipAssetOwner, uint8 ipAssetType) {
        vm.assume(ipAssetType > uint8(type(IPAsset).min));
        vm.assume(ipAssetType < uint8(type(IPAsset).max));
        ipAssetId = _createIPAsset(ipAssetOwner, IPAsset(ipAssetType));
        collectNFT = ICollectNFT(Clones.clone(collectNFTImpl));
        vm.prank(address(collectModule));
        collectNFT.initialize(InitCollectNFTParams({
            ipAssetRegistry: address(ipAssetRegistry),
            ipAssetId: ipAssetId,
            data: ""
        }));
        _;
    }

    function setUp() public virtual override(BaseERC721Test, BaseTest) { 
        super.setUp();
    }

    function test_CollectNFTCollect(address ipAssetOwner, uint8 ipAssetType) public createCollectNFT(ipAssetOwner, ipAssetType) {
        uint256 aliceBalance = collectNFT.balanceOf(alice);
        uint256 bobBalance = collectNFT.balanceOf(bob);
        uint256 totalSupply = collectNFT.totalSupply();
        vm.startPrank(address(collectModule));
        collectNFT.collect(alice, "");
        collectNFT.collect(alice, "");
        collectNFT.collect(bob, "");
        assertEq(collectNFT.totalSupply(), totalSupply + 3);
        assertEq(collectNFT.balanceOf(alice), aliceBalance + 2);
        assertEq(collectNFT.balanceOf(bob), bobBalance + 1);
    }
    
    function test_CollectNFTNonExistentIPAssetReverts() public {
        collectNFT = ICollectNFT(Clones.clone(collectNFTImpl));
        vm.expectRevert(CollectNFTIPAssetNonExistent.selector);
        collectNFT.initialize(InitCollectNFTParams({
            ipAssetRegistry: address(ipAssetRegistry),
            ipAssetId: ipAssetId,
            data: ""
        }));
    }

    function test_CollectNFTConstructorInitializeReverts() public {
        collectNFT = new MockCollectNFT();
        vm.expectRevert(CollectNFTAlreadyInitialized.selector);
        collectNFT.initialize(InitCollectNFTParams({
            ipAssetRegistry: address(ipAssetRegistry),
            ipAssetId: ipAssetId,
            data: ""
        }));
    }

    function test_CollectNFTNonCollectModuleCallerReverts(address ipAssetOwner, uint8 ipAssetType) public createCollectNFT(ipAssetOwner, ipAssetType) {
        vm.expectRevert(CollectNFTCallerUnauthorized.selector);
        collectNFT.collect(address(this), "");
    }

    function test_CollectNFTInitializeTwiceReverts(address ipAssetOwner, uint8 ipAssetType) public createCollectNFT(ipAssetOwner, ipAssetType) {
        vm.expectRevert(CollectNFTAlreadyInitialized.selector);
        collectNFT.initialize(InitCollectNFTParams({
            ipAssetRegistry: address(ipAssetRegistry),
            ipAssetId: ipAssetId,
            data: ""
        }));
    }

}
