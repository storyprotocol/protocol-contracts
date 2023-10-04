// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { SimpleCollectModule } from "contracts/modules/collect/SimpleCollectModule.sol";
import { BaseCollectModuleTest } from "./BaseCollectModuleTest.sol";
import { CollectParams } from "contracts/lib/CollectModuleStructs.sol";

/// @title Simple Collect Module Testing Contract
contract SimpleCollectModuleTest is BaseCollectModuleTest {

    function setUp() public virtual override(BaseCollectModuleTest) { 
        super.setUp();
    }

    /// @notice Tests that unauthorized collects revert.
    function test_CollectModuleCollectUnauthorizedReverts(uint8 ipAssetType) createIpAsset(collector, ipAssetType) public {
        vm.prank(alice);
        vm.expectRevert(CollectModuleCollectUnauthorized.selector);
        collectModule.collect(CollectParams({
            franchiseId: franchiseId,
            ipAssetId: ipAssetId,
            collector: collector,
            collectData: "",
            collectNFTInitData: "",
            collectNFTData: ""
        }));
    }

    /// @notice Tests that upgrades work as expected.
    function test_CollectModuleUpgrade() public {
        address newCollectModuleImpl = address(new SimpleCollectModule(address(franchiseRegistry), defaultCollectNFTImpl));
        vm.prank(upgrader);

        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256(bytes("DEFAULT_COLLECT_NFT_IMPL()")))
        );
        (bool success, ) = address(collectModule).call(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                newCollectModuleImpl,
                data
            )
        );
        assertTrue(success);
    }

    /// @notice Tests whether collect reverts if the registry of the IP asset being collected does not exist.
    function test_CollectModuleCollectNonExistentIPAssetRegistryReverts(uint256 nonExistentFranchiseId, uint8 ipAssetType) createIpAsset(collector, ipAssetType) public virtual override {
        vm.assume(nonExistentFranchiseId != franchiseId);
        vm.expectRevert();
        _collect(nonExistentFranchiseId, ipAssetId);
    }


    /// @notice Tests whether collect reverts if the IP asset being collected from does not exist.
    function test_CollectModuleCollectNonExistentIPAssetReverts(uint256 nonExistentipAssetId, uint8 ipAssetType) createIpAsset(collector, ipAssetType) public virtual override {
        vm.assume(nonExistentipAssetId != ipAssetId);
        vm.expectRevert();
        _collect(franchiseId, nonExistentipAssetId);
    }

    /// @notice Changes the base testing collect module deployment to deploy the mock payment collect module instead.
    function _deployCollectModule(address collectNFTImpl) internal virtual override  returns (address) {
        collectModuleImpl = address(new SimpleCollectModule(address(franchiseRegistry), collectNFTImpl));

        return _deployUUPSProxy(
                collectModuleImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
            )
        );

    }

}
