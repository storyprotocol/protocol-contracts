// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { ICollectModuleEventsAndErrors } from "contracts/interfaces/ICollectModuleEventsAndErrors.sol";
import { ICollectModule } from "contracts/interfaces/ICollectModule.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";

import { BaseTestUtils } from "test/foundry/utils/BaseTestUtils.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { CollectNFTBaseTest } from "./nft/CollectNFTBase.t.sol";
import { MockCollectModule, MockCollectModuleConstants } from "test/foundry/mocks/MockCollectModule.sol";
import { MockCollectNFT } from "test/foundry/mocks/MockCollectNFT.sol";

import { IPAsset } from "contracts/IPAsset.sol";
import { InitCollectParams, CollectParams } from "contracts/lib/CollectModuleStructs.sol";
import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";

/// @title Collect Module Base Testing Contract
/// @notice Tests all functionality provided by the base collect module.
contract CollectModuleBaseTest is BaseTest, ICollectModuleEventsAndErrors, MockCollectModuleConstants {

    // In the base collect module, an IP asset configured with a zero address
    // collect NFT impl means that the module-wide default should be used.
    address public constant DEFAULT_COLLECT_NFT_IMPL_CONFIG = address(0);

    function setUp() public virtual override(BaseTest) { 
        super.setUp();
    }

    // Id of IP asset which may differ per test based on testing constraints.
    uint256 ipAssetId;

    /// @notice Modifier that creates an IP asset for tsting.
    /// @param ipAssetOwner The owner address for the new IP asset.
    /// @param ipAssetType The type of the IP asset being created.
    modifier createIPAsset(address ipAssetOwner, uint8 ipAssetType) {
        ipAssetId = _createIPAsset(ipAssetOwner, ipAssetType);
        _;
    }

    /// @notice Tests whether an unauthorized collect reverts.
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

    /// @notice Tests whether unitialized modules revert on invoking collect.
    function test_CollectModuleCollectUninitializedReverts(address collector, address ipAssetOwner, uint8 ipAssetType) createIPAsset(ipAssetOwner, ipAssetType) public {
        address uninitializedCollectModuleImpl = address(new MockCollectModule(address(franchiseRegistry), address(new MockCollectNFT())));
        ICollectModule uninitializedCollectModule = ICollectModule(
            _deployUUPSProxy(
                collectModuleImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
        vm.assume(franchiseId != UNAUTHORIZED_FRANCHISE_ID);
        vm.expectRevert(CollectModuleCollectNotYetInitialized.selector);
        uninitializedCollectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

    /// @notice Tests whether collect reverts if the registry of the IP asset being collected does not exist.
    function test_CollectModuleCollectNonExistentIPAssetRegistryReverts(uint256 nonExistentFranchiseId, address collector, address ipAssetOwner, uint8 ipAssetType) createIPAsset(ipAssetOwner, ipAssetType) public {
        vm.assume(nonExistentFranchiseId != franchiseId);
        vm.expectRevert(CollectModuleIPAssetRegistryNonExistent.selector);
        _collect(nonExistentFranchiseId, ipAssetId, collector);
    }

    /// @notice Tests whether collect reverts if the IP asset being collected from does not exist.
    function test_CollectModuleCollectNonExistentIPAssetReverts(uint256 nonExistentIPAssetId, address collector, address ipAssetOwner, uint8 ipAssetType) createIPAsset(ipAssetOwner, ipAssetType) public {
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

    /// @notice Tests that collects with the module-default collect NFT succeed.
    function test_CollectModuleCollectDefaultCollectNFT(address collector, address ipAssetOwner, uint8 ipAssetType) createIPAsset(ipAssetOwner, ipAssetType) public {
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

    /// @notice Tests that collects with customized collect NFTs succeed.
    function test_CollectModuleCollectCustomCollectNFT(address ipAssetOwner, uint8 ipAssetType) public createIPAsset(ipAssetOwner, ipAssetType) {
        assertEq(collectModule.getCollectNFT(franchiseId, ipAssetId), address(0));
        (address collectNFT, uint256 collectNFTId) = collectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: alice,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
        assertEq(collectModule.getCollectNFT(franchiseId, ipAssetId), collectNFT);
        assertTrue(ICollectNFT(collectNFT).ownerOf(collectNFTId) == alice);
    }

    /// @notice Tests expected behavior of the collect module constructor.
    function test_CollectModuleConstructor() public {
        MockCollectModule mockCollectModule = new MockCollectModule(address(franchiseRegistry), defaultCollectNFTImpl);
        assertEq(address(mockCollectModule.FRANCHISE_REGISTRY()), address(franchiseRegistry));
    }

    /// @notice Tests expected behavior of collect module initialization.
    function test_CollectModuleInit(address ipAssetOwner, uint8 ipAssetType) public {
        assertEq(address(0), collectModule.getCollectNFT(franchiseId, ipAssetId));
        // _initCollectModule(franchiseId, ipAssetOwner, ipAssetType, DEFAULT_COLLECT_NFT_IMPL_CONFIG);
    }

    /// @notice Tests collect module reverts on unauthorized calls.
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

    /// @notice Tests collect module reverts on duplicate initialization.
    function test_CollectModuleDuplicateInitReverts(address ipAssetOwner, uint8 ipAssetType) createIPAsset(ipAssetOwner, ipAssetType) public {
        vm.prank(address(ipAssetRegistry));
        vm.expectRevert(CollectModuleIPAssetAlreadyInitialized.selector);
        collectModule.initCollect(InitCollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collectNFTImpl: DEFAULT_COLLECT_NFT_IMPL_CONFIG,
            data: ""
        }));
    }

    /// @dev Helper function that initializes a collect module.
    /// @param franchiseId The id of the franchise associated with the module.
    /// @param ipAssetOwner Owner address of the module configured IP asset.
    /// @param ipAssetType IP asset type of the module configured IP asset.
    /// @param collectNFTImpl Collect NFT impl address used for collecting.
    function _initCollectModule(uint256 franchiseId, address ipAssetOwner, uint8 ipAssetType, address collectNFTImpl) internal createIPAsset(ipAssetOwner, ipAssetType) {
        vm.prank(address(ipAssetRegistry));
        collectModule.initCollect(InitCollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collectNFTImpl: collectNFTImpl,
            data: ""
        }));
    }

    /// @dev Helper function that performs collect module collection.
    /// @param franchiseId The id of the franchise of the IP asset.
    /// @param ipAssetId_ The id of the IP asset being collected.
    /// @param collector Address designated for the IP asset collection.
    function _collect(uint256 franchiseId, uint256 ipAssetId_, address collector) internal {
        vm.assume(franchiseId != UNAUTHORIZED_FRANCHISE_ID);
        collectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId_,
            collector: collector,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }
}
