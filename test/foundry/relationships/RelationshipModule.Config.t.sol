// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import '../utils/BaseTest.sol';

contract RelationshipModuleSetupRelationshipsTest is BaseTest {

    function setUp() virtual override public {
        deployProcessors = true;
        super.setUp();
    }

    function test_setRelationship() public {
        IPAsset[] memory sourceIPAssets = new IPAsset[](1);
        sourceIPAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIPAssets = new IPAsset[](2);
        destIPAssets[0] = IPAsset.CHARACTER;
        destIPAssets[1] = IPAsset.ART;
        
        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTTL: 0,
                maxTTL: 0,
                renewable: false
            })
        });

        bytes32 relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
        assertEq(relId, keccak256(abi.encode("RELATIONSHIP")));

        IRelationshipModule.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relId);
        assertEq(config.sourceIPAssetTypeMask, 1 << (uint256(IPAsset.STORY) & 0xff));
        assertEq(config.destIPAssetTypeMask, 1 << (uint256(IPAsset.CHARACTER) & 0xff) | 1 << (uint256(IPAsset.ART) & 0xff) | (uint256(EXTERNAL_ASSET) << 248));
        assertTrue(config.onlySameFranchise);
        // TODO: test for event

    }

    function test_revert_IfMasksNotConfigured() public {
        IPAsset[] memory sourceIPAssets = new IPAsset[](1);
        sourceIPAssets[0] = IPAsset.UNDEFINED;
        IPAsset[] memory destIPAssets = new IPAsset[](2);

        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTTL: 0,
                maxTTL: 0,
                renewable: false
            })
        });

        vm.expectRevert();
        relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
    }

    function test_relationshipConfigDecoded() public {
        IPAsset[] memory sourceIPAssets = new IPAsset[](1);
        sourceIPAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIPAssets = new IPAsset[](2);
        destIPAssets[0] = IPAsset.CHARACTER;
        destIPAssets[1] = IPAsset.ART;
        
        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTTL: 0,
                maxTTL: 0,
                renewable: false
            })
        });
        bytes32 relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);

        IRelationshipModule.SetRelationshipConfigParams memory result = relationshipModule.getRelationshipConfigDecoded(relId);

        _assertEqIPAssetArray(result.sourceIPAssets, params.sourceIPAssets);
        _assertEqIPAssetArray(result.destIPAssets, params.destIPAssets);
        assertEq(result.allowedExternalSource, params.allowedExternalSource);
        assertEq(result.allowedExternalDest, params.allowedExternalDest);
        assertEq(result.onlySameFranchise, params.onlySameFranchise);
        assertEq(result.processor, params.processor);
        assertEq(result.disputer, params.disputer);
        assertEq(result.timeConfig.minTTL, params.timeConfig.minTTL);
        assertEq(result.timeConfig.maxTTL, params.timeConfig.maxTTL);
        assertEq(result.timeConfig.renewable, params.timeConfig.renewable);

    }

    function _assertEqIPAssetArray(IPAsset[] memory result, IPAsset[] memory expected) internal {
        for (uint256 i = 0; i < result.length; i++) {
            if (i < expected.length) {
                assertEq(uint256(result[i]), uint256(expected[i]));
            } else {
                assertEq(uint256(result[i]), 0);
            }
        }
    }

}

contract RelationshipModuleUnsetRelationshipsTest is BaseTest {


    bytes32 relationshipId;

    function setUp() virtual override public {
        deployProcessors = true;
        super.setUp();
        IPAsset[] memory sourceIPAssets = new IPAsset[](1);
        sourceIPAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIPAssets = new IPAsset[](1);
        destIPAssets[0] = IPAsset.CHARACTER;
        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTTL: 0,
                maxTTL: 0,
                renewable: false
            })
        });
        relationshipId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
    }

    function test_unsetRelationshipConfig() public {
        relationshipModule.unsetRelationshipConfig(relationshipId);

        IRelationshipModule.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relationshipId);
        assertEq(config.sourceIPAssetTypeMask, 0);
        assertEq(config.destIPAssetTypeMask, 0);
        assertFalse(config.onlySameFranchise);
        // TODO: test for event
    }

    function test_revert_unsetRelationshipConfigNonExistingRelationship() public {
        bytes32 id = relationshipModule.getRelationshipId("UNDEFINED_Relationship");
        vm.expectRevert(IRelationshipModule.NonExistingRelationship.selector);
        relationshipModule.unsetRelationshipConfig(id);
    }

}
