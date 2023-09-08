// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IPAsset } from "contracts/IPAsset.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";
import { InitCollectParams, CollectParams } from "contracts/lib/CollectModuleStructs.sol";
import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";
import { MockCollectNFT } from "test/foundry/mocks/MockCollectNFT.sol";
import { MockCollectModule, MockCollectModuleConstants } from "test/foundry/mocks/MockCollectModule.sol";
import { BaseTestUtils } from "test/foundry/utils/BaseTestUtils.sol";
import { ICollectModuleEventsAndErrors } from "contracts/interfaces/ICollectModuleEventsAndErrors.sol";
import { CollectNFTBaseTest } from "./nft/CollectNFTBase.t.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";

contract CollectModuleBaseTest is BaseTest, ICollectModuleEventsAndErrors, MockCollectModuleConstants {

    address public constant DEFAULT_COLLECT_NFT_IMPL_CONFIG = address(0);

    function setUp() public virtual override(BaseTest) { 

        super.setUp();
    }

    uint256 ipAssetId;

    modifier createIPAsset(address ipAssetOwner, uint8 ipAssetType) {
        ipAssetId = _createIPAsset(ipAssetOwner, ipAssetType);
        _;
    }

    modifier initCollectModule(address ipAssetOwner, uint8 ipAssetType) {
        _initCollectModule(franchiseId, ipAssetOwner, ipAssetType, DEFAULT_COLLECT_NFT_IMPL_CONFIG);
        _;
    }

    function test_CollectModuleCollectUnauthorizedCallReverts(address collector, address ipAssetOwner, uint8 ipAssetType) createIPAsset(ipAssetOwner, ipAssetType) public {
        vm.expectRevert(CollectModuleCollectUnauthorized.selector);
        collectModule.collect(CollectParams({
            franchiseId: UNAUTHORIZED_FRANCHISE_ID,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

    function test_CollectModuleCollectUninitializedReverts(address collector, address ipAssetOwner, uint8 ipAssetType) createIPAsset(ipAssetOwner, ipAssetType) public {
        vm.expectRevert(CollectModuleCollectNotYetInitialized.selector);
        _collect(franchiseId, ipAssetId, collector);
    }

    function test_CollectModuleCollectNonExistentIPAssetRegistryReverts(uint256 franchiseId, address collector, address ipAssetOwner, uint8 ipAssetType) initCollectModule(ipAssetOwner, ipAssetType) public {
        vm.assume(franchiseId != ipAssetRegistry.franchiseId());
        vm.expectRevert(CollectModuleIPAssetRegistryNonExistent.selector);
        _collect(franchiseId, ipAssetId, collector);
    }

    function test_CollectModuleCollectNonExistentIPAssetReverts(uint256 nonExistentIPAssetId, address collector, address ipAssetOwner, uint8 ipAssetType) initCollectModule(ipAssetOwner, ipAssetType) public {
        vm.assume(nonExistentIPAssetId != ipAssetId);
        vm.assume(nonExistentIPAssetId != UNAUTHORIZED_FRANCHISE_ID);
        vm.expectRevert(CollectModuleIPAssetNonExistent.selector);
        collectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: nonExistentIPAssetId,
            collector: collector,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

    function test_CollectModuleCollectDefaultCollectNFT(address collector, address ipAssetOwner, uint8 ipAssetType) initCollectModule(ipAssetOwner, ipAssetType) public {
        vm.assume(collector != address(0));
        assertEq(collectModule.getCollectNFT(franchiseId, ipAssetId), address(0));
        (address collectNFT, uint256 collectNFTId) = collectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
        assertEq(collectModule.getCollectNFT(franchiseId, ipAssetId), collectNFT);
        assertTrue(ICollectNFT(collectNFT).ownerOf(collectNFTId) == collector);
    }

    function test_CollectModuleCollectCustomCollectNFT(address collector, address ipAssetOwner, uint8 ipAssetType) public {
        address customCollectNFTImpl = address(new MockCollectNFT());
        _initCollectModule(franchiseId, ipAssetOwner, ipAssetType, customCollectNFTImpl);
        vm.assume(collector != address(0));
        assertEq(collectModule.getCollectNFT(franchiseId, ipAssetId), address(0));
        (address collectNFT, uint256 collectNFTId) = collectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
        assertEq(collectModule.getCollectNFT(franchiseId, ipAssetId), collectNFT);
        assertTrue(ICollectNFT(collectNFT).ownerOf(collectNFTId) == collector);
    }

    function test_CollectModuleConstructor() public {
        MockCollectModule mockCollectModule = new MockCollectModule(address(franchiseRegistry), defaultCollectNFTImpl);
        assertEq(address(mockCollectModule.FRANCHISE_REGISTRY()), address(franchiseRegistry));
    }

    function test_CollectModuleInit(address ipAssetOwner, uint8 ipAssetType) public {
        assertEq(address(0), collectModule.getCollectNFT(franchiseId, ipAssetId));
        _initCollectModule(franchiseId, ipAssetOwner, ipAssetType, DEFAULT_COLLECT_NFT_IMPL_CONFIG);
    }

    function test_CollectModuleInitCollectInvalidCallerReverts(uint256 nonExistentFranchiseId, address ipAssetOwner, uint8 ipAssetType) public createIPAsset(ipAssetOwner, ipAssetType)  {
        vm.assume(nonExistentFranchiseId != franchiseId);
        vm.expectRevert(CollectModuleCallerUnauthorized.selector);
        vm.prank(address(this));
        collectModule.initCollect(InitCollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collectNFTImpl: defaultCollectNFTImpl,
            data: ""
        }));
    }

    function test_CollectModuleDuplicateInitReverts(address ipAssetOwner, uint8 ipAssetType) public {
        _initCollectModule(franchiseId, ipAssetOwner, ipAssetType, DEFAULT_COLLECT_NFT_IMPL_CONFIG);
        vm.prank(address(ipAssetRegistry));
        vm.expectRevert(CollectModuleIPAssetAlreadyInitialized.selector);
        collectModule.initCollect(InitCollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collectNFTImpl: DEFAULT_COLLECT_NFT_IMPL_CONFIG,
            data: ""
        }));
    }

    function _initCollectModule(uint256 franchiseId, address ipAssetOwner, uint8 ipAssetType, address collectNFTImpl) internal createIPAsset(ipAssetOwner, ipAssetType) {
        vm.prank(address(ipAssetRegistry));
        collectModule.initCollect(InitCollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collectNFTImpl: collectNFTImpl,
            data: ""
        }));
    }

    function _collect(uint256 franchiseId, uint256 ipAssetId, address collector) internal {
        vm.assume(franchiseId != UNAUTHORIZED_FRANCHISE_ID);
        collectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

}
