// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import { ICollectModuleEventsAndErrors } from "contracts/interfaces/ICollectModuleEventsAndErrors.sol";
import { ICollectModule } from "contracts/interfaces/ICollectModule.sol";
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";

import { BaseTestUtils } from "test/foundry/utils/BaseTestUtils.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { BaseCollectModuleTest } from "./BaseCollectModuleTest.sol";
import { CollectNFTBaseTest } from "./nft/CollectNFTBase.t.sol";
import { MockCollectModule } from "test/foundry/mocks/MockCollectModule.sol";
import { MockCollectNFT } from "test/foundry/mocks/MockCollectNFT.sol";

import { IPAsset } from "contracts/IPAsset.sol";
import { InitCollectParams, CollectParams } from "contracts/lib/CollectModuleStructs.sol";
import { InitCollectNFTParams } from "contracts/lib/CollectNFTStructs.sol";

/// @title Collect Module Base Testing Contract
/// @notice Tests all functionality provided by the base collect module.
contract CollectModuleBaseTest is BaseCollectModuleTest {

    function setUp() public virtual override(BaseCollectModuleTest) { 
        super.setUp();
    }

    // /// @notice Tests whether an unauthorized collect reverts.
    // function test_CollectModuleCollectUnauthorizedCallReverts(address collector, uint8 ipAssetType) createIPAsset(alice, ipAssetType) public {
    //     vm.expectRevert(CollectModuleCollectUnauthorized.selector);
    //     collectModule.collect(CollectParams({
    //         franchiseId: UNAUTHORIZED_FRANCHISE_ID,
    //         ipAssetId: ipAssetId,
    //         collector: collector,
    //         collectData: "",
    //         collectNFTInitData: "",
    //         collectNFTData: ""
    //     }));
    // }


}
