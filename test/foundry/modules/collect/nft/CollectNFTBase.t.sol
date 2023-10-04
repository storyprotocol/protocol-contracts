// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';

import { ICollectNFT } from "contracts/interfaces/modules/collect/ICollectNFT.sol";
import { ICollectNFTEventsAndErrors } from "contracts/interfaces/modules/collect/ICollectNFTEventsAndErrors.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { BaseERC721Test } from "./BaseERC721Test.sol";
import { MockCollectNFT } from "test/foundry/mocks/MockCollectNFT.sol";
import { ERC721Test } from "./ERC721.t.sol";

import { IPAsset } from "contracts/IPAsset.sol";
import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";

/// @title Collect NFT Base Testing Contract
/// @notice Tests all functionality provided by the base collect NFT.
contract CollectNFTBaseTest is BaseERC721Test, BaseTest, ICollectNFTEventsAndErrors {

    // Id of IP asset which may differ per test based on testing constraints.
    uint256 ipAssetId;

    // Collect NFT which may differ per test based on testing constraints.
    ICollectNFT collectNFT;

    /// @notice Modifier that creates a collect NFT for testing.
    /// @param ipAssetOwner The owner address for the new IP asset.
    /// @param ipAssetType The type of the IP asset being created.
    modifier createCollectNFT(address ipAssetOwner, uint8 ipAssetType) {
        ipAssetId = _createIPAsset(ipAssetOwner, ipAssetType, "");
        collectNFT = ICollectNFT(Clones.clone(defaultCollectNFTImpl));
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

    /// @notice Tests whether collect module collection is successful.
    function test_CollectNFTCollect(uint8 ipAssetType) public createCollectNFT(cal, ipAssetType) {
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
    
    /// @notice Tests whether collect on non-existent IP assets revert.
    function test_CollectNFTNonExistentIPAssetReverts() public {
        collectNFT = ICollectNFT(Clones.clone(defaultCollectNFTImpl));
        vm.expectRevert(CollectNFTIPAssetNonExistent.selector);
        collectNFT.initialize(InitCollectNFTParams({
            ipAssetRegistry: address(ipAssetRegistry),
            ipAssetId: ipAssetId,
            data: ""
        }));
    }

    /// @notice Tests whether initialization on a deployed collect NFT reverts.
    function test_CollectNFTConstructorInitializeReverts() public {
        collectNFT = new MockCollectNFT();
        vm.expectRevert(CollectNFTAlreadyInitialized.selector);
        collectNFT.initialize(InitCollectNFTParams({
            ipAssetRegistry: address(ipAssetRegistry),
            ipAssetId: ipAssetId,
            data: ""
        }));
    }

    /// @notice Tests whether collect calls not made by the collect module revert.
    function test_CollectNFTNonCollectModuleCallerReverts(uint8 ipAssetType) public createCollectNFT(cal, ipAssetType) {
        vm.expectRevert(CollectNFTCallerUnauthorized.selector);
        collectNFT.collect(address(this), "");
    }

    /// @notice Tests whether re-initialization of collect module settings revert.
    function test_CollectNFTInitializeTwiceReverts(uint8 ipAssetType) public createCollectNFT(cal, ipAssetType) {
        vm.expectRevert(CollectNFTAlreadyInitialized.selector);
        collectNFT.initialize(InitCollectNFTParams({
            ipAssetRegistry: address(ipAssetRegistry),
            ipAssetId: ipAssetId,
            data: ""
        }));
    }

}
