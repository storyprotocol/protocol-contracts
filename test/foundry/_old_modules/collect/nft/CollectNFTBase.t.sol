// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { Clones } from '@openzeppelin/contracts/proxy/Clones.sol';

import { ICollectNFT } from "contracts/interfaces/modules/collect/ICollectNFT.sol";

import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { BaseERC721Test } from "./BaseERC721Test.sol";
import { MockCollectNFT } from "test/foundry/mocks/MockCollectNFT.sol";
import { ERC721Test } from "./ERC721.t.sol";

import { IPAsset } from "contracts/lib/IPAsset.sol";
import { Collect } from "contracts/lib/modules/Collect.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Collect NFT Base Testing Contract
/// @notice Tests all functionality provided by the base collect NFT.
contract CollectNFTBaseTest is BaseERC721Test, BaseTest {

    // Id of IP asset which may differ per test based on testing constraints.
    uint256 ipAssetId;

    // Collect NFT which may differ per test based on testing constraints.
    ICollectNFT collectNft;

    /// @notice Modifier that creates a collect NFT for testing.
    /// @param ipAssetOwner The owner address for the new IP asset.
    /// @param ipAssetType The type of the IP asset being created.
    modifier createCollectNFT(address ipAssetOwner, uint8 ipAssetType) {
        ipAssetId = _createIpAsset(ipAssetOwner, ipAssetType, "");
        collectNft = ICollectNFT(Clones.clone(defaultCollectNftImpl));
        vm.prank(address(collectModule));
        collectNft.initialize(Collect.InitCollectNFTParams({
            registry: address(registry),
            ipAssetOrg: address(ipOrg),
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
        uint256 aliceBalance = collectNft.balanceOf(alice);
        uint256 bobBalance = collectNft.balanceOf(bob);
        uint256 totalSupply = collectNft.totalSupply();
        vm.startPrank(address(collectModule));
        collectNft.collect(alice, "");
        collectNft.collect(alice, "");
        collectNft.collect(bob, "");
        assertEq(collectNft.totalSupply(), totalSupply + 3);
        assertEq(collectNft.balanceOf(alice), aliceBalance + 2);
        assertEq(collectNft.balanceOf(bob), bobBalance + 1);
    }
    
    /// @notice Tests whether collect on non-existent IP assets revert.
    function test_CollectNFTNonExistentIPAssetReverts() public {
        collectNft = ICollectNFT(Clones.clone(defaultCollectNftImpl));
        vm.expectRevert(Errors.CollectNFT_IPAssetNonExistent.selector);
        collectNft.initialize(Collect.InitCollectNFTParams({
            registry: address(registry),
            ipAssetOrg: address(ipOrg),
            ipAssetId: 99,
            data: ""
        }));
    }

    /// @notice Tests whether initialization on a deployed collect NFT reverts.
    function test_CollectNFTConstructorInitializeReverts() public {
        collectNft = new MockCollectNFT();
        vm.expectRevert(Errors.CollectNFT_AlreadyInitialized.selector);
        collectNft.initialize(Collect.InitCollectNFTParams({
            registry: address(registry),
            ipAssetOrg: address(ipOrg),
            ipAssetId: ipAssetId,
            data: ""
        }));
    }

    /// @notice Tests whether collect calls not made by the collect module revert.
    function test_CollectNFTNonCollectModuleCallerReverts(uint8 ipAssetType) public createCollectNFT(cal, ipAssetType) {
        vm.expectRevert(Errors.CollectNFT_CallerUnauthorized.selector);
        collectNft.collect(address(this), "");
    }

    /// @notice Tests whether re-initialization of collect module settings revert.
    function test_CollectNFTInitializeTwiceReverts(uint8 ipAssetType) public createCollectNFT(cal, ipAssetType) {
        vm.expectRevert(Errors.CollectNFT_AlreadyInitialized.selector);
        collectNft.initialize(Collect.InitCollectNFTParams({
            registry: address(registry),
            ipAssetOrg: address(ipOrg),
            ipAssetId: ipAssetId,
            data: ""
        }));
    }

}
