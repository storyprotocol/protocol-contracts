// SPDX-License-Identifier: UNLICENSED
// See Story Protocol Alpha Agreement: https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.18;

import { SimpleCollectModule } from "contracts/modules/collect/SimpleCollectModule.sol";
import { BaseCollectModuleTest } from "./BaseCollectModuleTest.sol";
import { Collect } from "contracts/lib/modules/Collect.sol";
import { Errors } from "contracts/lib/Errors.sol";

/// @title Simple Collect Module Testing Contract
contract SimpleCollectModuleTest is BaseCollectModuleTest {

    function setUp() public virtual override(BaseCollectModuleTest) { 
        super.setUp();
    }

    /// @notice Tests that unauthorized collects revert.
    // function test_CollectModuleCollectUnauthorizedReverts(uint8 ipAssetType) createIpAsset(collector, ipAssetType) public {
    //     vm.prank(alice);
    //     vm.expectRevert(Errors.CollectModule_CollectUnauthorized.selector);
    //     collectModule.collect(Collect.CollectParams({
    //         ipAssetId: ipAssetId,
    //         collector: collector,
    //         collectData: "",
    //         collectNftInitData: "",
    //         collectNftData: ""
    //     }));
    // }

    // /// @notice Tests that upgrades work as expected.
    // function test_CollectModuleUpgrade() public {
    //     address newCollectModuleImpl = address(new SimpleCollectModule(address(registry), defaultCollectNftImpl));
    //     vm.prank(upgrader);

    //     bytes memory data = abi.encodeWithSelector(
    //         bytes4(keccak256(bytes("DEFAULT_COLLECT_NFT_IMPL()")))
    //     );
    //     (bool success, ) = address(collectModule).call(
    //         abi.encodeWithSignature(
    //             "upgradeToAndCall(address,bytes)",
    //             newCollectModuleImpl,
    //             data
    //         )
    //     );
    //     assertTrue(success);
    // }


    // /// @notice Tests whether collect reverts if the IP asset being collected from does not exist.
    // function test_CollectModuleCollectNonExistentIPAssetReverts(uint256 nonExistentipAssetId, uint8 ipAssetType) createIpAsset(collector, ipAssetType) public virtual override {
    //     vm.assume(nonExistentipAssetId != ipAssetId);
    //     vm.expectRevert();
    //     _collect(99);
    // }

    /// @notice Changes the base testing collect module deployment to deploy the mock payment collect module instead.
    function _deployCollectModule(address collectNftImpl) internal virtual override  returns (address) {
        collectModuleImpl = address(new SimpleCollectModule(address(registry), collectNftImpl));

        return _deployUUPSProxy(
                collectModuleImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
            )
        );

    }

}
