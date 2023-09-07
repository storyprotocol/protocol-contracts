// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { IPAsset } from "contracts/IPAsset.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";
import { InitCollectParams, CollectParams } from "contracts/lib/CollectModuleStructs.sol";
import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";
import { MockCollectModule, MockCollectModuleConstants } from "test/foundry/mocks/MockCollectModule.sol";
import { BaseTestUtils } from "test/foundry/utils/BaseTestUtils.sol";
import { ICollectModuleEventsAndErrors } from "contracts/interfaces/ICollectModuleEventsAndErrors.sol";
import { CollectNFTBaseTest } from "./nft/CollectNFTBase.t.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";

contract CollectModuleBaseTest is BaseTest, ICollectModuleEventsAndErrors, MockCollectModuleConstants {

    function setUp() public virtual override(BaseTest) { 
        super.setUp();
    }

    uint256 ipAssetId;

    modifier createIPAsset(address ipAssetOwner, uint8 ipAssetType) {
        vm.assume(ipAssetType > uint8(type(IPAsset).min));
        vm.assume(ipAssetType < uint8(type(IPAsset).max));
        ipAssetId = _createIPAsset(ipAssetOwner, IPAsset(ipAssetType));
        _;
    }

    modifier initCollectModule(address ipAssetOwner, uint8 ipAssetType) {
        _initCollectModule(ipAssetRegistry.franchiseId(), ipAssetOwner, ipAssetType);
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
        uint256 franchiseId = ipAssetRegistry.franchiseId();
        vm.expectRevert(CollectModuleCollectNotYetInitialized.selector);
        _collect(franchiseId, ipAssetId, collector);
    }

    function test_CollectModuleCollectNonExistentIPAssetRegistryReverts(uint256 franchiseId, address collector, address ipAssetOwner, uint8 ipAssetType) initCollectModule(ipAssetOwner, ipAssetType) public {
        vm.assume(franchiseId != ipAssetRegistry.franchiseId());
        vm.expectRevert(CollectModuleIPAssetRegistryNonExistent.selector);
        _collect(franchiseId, ipAssetId, collector);
    }

    function test_CollectModuleCollectNonExistentIPAssetReverts(uint256 nonExistentIPAssetId, address collector, address ipAssetOwner, uint8 ipAssetType) initCollectModule(ipAssetOwner, ipAssetType) public {
        uint256 franchiseId = ipAssetRegistry.franchiseId();
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

    function test_CollectModuleCollect(address collector, address ipAssetOwner, uint8 ipAssetType) initCollectModule(ipAssetOwner, ipAssetType) public {
        assertEq(address(0), collectModule.getCollectNFT(franchiseId, ipAssetId));
        uint256 franchiseId = ipAssetRegistry.franchiseId();
        collectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

    function test_CollectModuleConstructor() public {
        MockCollectModule mockCollectModule = new MockCollectModule(address(franchiseRegistry), collectNFTImpl);
        assertEq(address(mockCollectModule.FRANCHISE_REGISTRY()), address(franchiseRegistry));
    }

    function test_CollectModuleInit(address ipAssetOwner, uint8 ipAssetType) public {
        uint256 franchiseId = ipAssetRegistry.franchiseId();
        assertEq(address(0), collectModule.getCollectNFT(franchiseId, ipAssetId));
        _initCollectModule(franchiseId, ipAssetOwner, ipAssetType);
    }

    function test_CollectModuleInitCollectInvalidCallerReverts(uint256 franchiseId, address ipAssetOwner, uint8 ipAssetType) public createIPAsset(ipAssetOwner, ipAssetType)  {
        vm.assume(franchiseId != ipAssetRegistry.franchiseId());
        vm.expectRevert(CollectModuleCallerUnauthorized.selector);
        vm.prank(address(this));
        collectModule.initCollect(InitCollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collectNFTImpl: collectNFTImpl,
            data: ""
        }));
    }

    function test_CollectModuleDuplicateInitReverts(address ipAssetOwner, uint8 ipAssetType) public {
        uint256 franchiseId = ipAssetRegistry.franchiseId();
        _initCollectModule(franchiseId, ipAssetOwner, ipAssetType);
        vm.prank(address(ipAssetRegistry));
        vm.expectRevert(CollectModuleIPAssetAlreadyInitialized.selector);
        collectModule.initCollect(InitCollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collectNFTImpl: collectNFTImpl,
            data: ""
        }));
    }

    function _initCollectModule(uint256 franchiseId, address ipAssetOwner, uint8 ipAssetType) internal createIPAsset(ipAssetOwner, ipAssetType) {
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
