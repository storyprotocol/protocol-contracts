// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { ICollectModule } from "contracts/interfaces/modules/collect/ICollectModule.sol";
import { ICollectNFT } from "contracts/interfaces/modules/collect/ICollectNFT.sol";

import { BaseTestUtils } from "test/foundry/utils/BaseTestUtils.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { CollectNFTBaseTest } from "./nft/CollectNFTBase.t.sol";
import { MockCollectModule } from "test/foundry/mocks/MockCollectModule.sol";
import { MockCollectNFT } from "test/foundry/mocks/MockCollectNFT.sol";

import { IPAsset } from "contracts/lib/IPAsset.sol";
import { Collect } from "contracts/lib/modules/Collect.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Collect Module Base ERC-721 Testing Utility Contract
/// @notice Provides a set of reusable tests for ERC-721 implementations.
contract BaseCollectModuleTest is BaseTest {

    // TODO: Currently, when compiling with 0.8.21, there is a known ICE bug that prevents us from emitting from the interface directly e.g. via ICollectModule.Collected - these two should be refactored in favor of emitting through the interface once we officially migrate to 0.8.22.
    // See: https://github.com/ethereum/solidity/issues/14430
    event Collected(
        uint256 indexed ipAssetId_,
        address indexed collector_,
        address collectNft_,
        uint256 collectNftId_,
        bytes collectData_,
        bytes collectNftData_
    );

    // TODO: Refactor once we migrate to compiling via 0.8.22 as explained above.
    event NewCollectNFT(
        uint256 indexed ipAssetId_,
        address collectNFT_
    );

    // In the base collect module, an IP asset configured with a zero address
    // collect NFT impl means that the module-wide default should be used.
    address public constant DEFAULT_COLLECT_NFT_IMPL_CONFIG = address(0);

    // Id of IP asset which may differ per test based on testing constraints.
    uint256 ipAssetId;
    address payable collector;

    /// @notice Modifier that creates an IP asset for testing.
    /// @param ipAssetOwner The owner address for the new IP asset.
    /// @param ipAssetType The type of the IP asset being created.
    modifier createIpAsset(address ipAssetOwner, uint8 ipAssetType) virtual {
        ipAssetId = _createIpAsset(ipAssetOwner, ipAssetType, "");
        _;
    }

    /// @notice Sets up the base collect module for running tests.
    function setUp() public virtual override(BaseTest) { 
        super.setUp();
        collector = cal;
    }


    /// @notice Tests whether collect reverts if the IP asset being collected from does not exist.
    function test_CollectModuleCollectNonExistentIPAssetReverts(uint256 nonExistentipAssetId, uint8 ipAssetType) createIpAsset(collector, ipAssetType) public virtual {
        vm.assume(nonExistentipAssetId != ipAssetId);
        vm.expectRevert(Errors.CollectModule_IPAssetNonExistent.selector);
        _collect(nonExistentipAssetId);
    }

    /// @notice Tests that collects with the module-default collect NFT succeed.
    function test_CollectModuleCollectDefaultCollectNFT(uint8 ipAssetType) createIpAsset(collector, ipAssetType) public {
        assertEq(collectModule.getCollectNFT(ipAssetId), address(0));
        vm.expectEmit(true, true, false, false, address(collectModule));
        emit NewCollectNFT(
            ipAssetId,
            defaultCollectNftImpl
        );
        vm.expectEmit(true, true, true, false, address(collectModule));
        emit Collected(
            ipAssetId,
            collector,
            defaultCollectNftImpl,
            0,
            "",
            ""
        );
        (address collectNft, uint256 collectNftId) = _collect(ipAssetId);
        assertEq(collectModule.getCollectNFT(ipAssetId), collectNft);
        assertTrue(ICollectNFT(collectNft).ownerOf(collectNftId) == cal);
        assertEq(collectModule.getCollectNFT(ipAssetId), collectNft);
    }

    /// @notice Tests that collects with customized collect NFTs succeed.
    function test_CollectModuleCollectCustomCollectNFT(uint8 ipAssetType) public createIpAsset(collector, ipAssetType) {
        assertEq(collectModule.getCollectNFT(ipAssetId), address(0));
        vm.expectEmit(true, true, false, false, address(collectModule));
        emit NewCollectNFT(
            ipAssetId,
            defaultCollectNftImpl
        );
        vm.expectEmit(true, true, true, false, address(collectModule));
        emit Collected(
            ipAssetId,
            collector,
            defaultCollectNftImpl,
            0,
            "",
            ""
        );
        (address collectNft, uint256 collectNftId) = _collect(ipAssetId);
        assertEq(collectModule.getCollectNFT(ipAssetId), collectNft);
        assertTrue(ICollectNFT(collectNft).ownerOf(collectNftId) == cal);
    }

    /// @notice Tests expected behavior of the collect module constructor.
    function test_CollectModuleConstructor() public {
        MockCollectModule mockCollectModule = new MockCollectModule(address(registry), defaultCollectNftImpl);
        assertEq(address(mockCollectModule.REGISTRY()), address(registry));
    }

    /// @notice Tests expected behavior of collect module initialization.
    function test_CollectModuleInit() public {
        assertEq(address(0), collectModule.getCollectNFT(ipAssetId));
    }

    /// @notice Tests collect module reverts on unauthorized calls.
    function test_CollectModuleInitCollectInvalidCallerReverts(uint256 nonExistentIPOrgId, uint8 ipAssetType) public createIpAsset(collector, ipAssetType)  {
        vm.expectRevert(Errors.CollectModule_CallerUnauthorized.selector);
        vm.prank(address(this));
        collectModule.initCollect(Collect.InitCollectParams({
            ipAssetId: ipAssetId,
            collectNftImpl: defaultCollectNftImpl,
            data: ""
        }));
    }

    /// @notice Tests collect module reverts on duplicate initialization.
    function test_CollectModuleDuplicateInitReverts(uint8 ipAssetType) createIpAsset(collector, ipAssetType) public {
        vm.expectRevert(Errors.CollectModule_IPAssetAlreadyInitialized.selector);
        vm.prank(address(ipOrg));
        _initCollectModule(defaultCollectNftImpl);
    }

    /// @dev Helper function that initializes a collect module.
    /// @param collectNftImpl Collect NFT impl address used for collecting.
    function _initCollectModule( address collectNftImpl) internal virtual {
        collectModule.initCollect(Collect.InitCollectParams({
            ipAssetId: ipAssetId,
            collectNftImpl: collectNftImpl,
            data: ""
        }));
    }

    /// @dev Helper function that performs collect module collection.
    /// @param ipAssetId_ The id of the IP asset being collected.
    function _collect(uint256 ipAssetId_) internal virtual returns (address, uint256) {
        vm.prank(address(ipOrg));
        return collectModule.collect(Collect.CollectParams({
            ipAssetId: ipAssetId_,
            collector: collector,
            collectData: "",
            collectNftInitData: "",
            collectNftData: ""
        }));
    }

}
