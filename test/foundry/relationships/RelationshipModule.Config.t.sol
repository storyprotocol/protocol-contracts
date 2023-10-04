// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import '../utils/BaseTest.sol';

contract RelationshipModuleSetupRelationshipsTest is BaseTest {

    function setUp() virtual override public {
        deployProcessors = true;
        super.setUp();
    }

    function test_setRelationship() public {
        IPAsset[] memory sourceIpAssets = new IPAsset[](1);
        sourceIpAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIpAssets = new IPAsset[](2);
        destIpAssets[0] = IPAsset.CHARACTER;
        destIpAssets[1] = IPAsset.ART;
        
        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIpAssets: sourceIpAssets,
            allowedExternalSource: false,
            destIpAssets: destIpAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });

        bytes32 relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
        assertEq(relId, keccak256(abi.encode("RELATIONSHIP")));

        IRelationshipModule.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relId);
        assertEq(config.sourceIpAssetTypeMask, 1 << (uint256(IPAsset.STORY) & 0xff));
        assertEq(config.destIpAssetTypeMask, 1 << (uint256(IPAsset.CHARACTER) & 0xff) | 1 << (uint256(IPAsset.ART) & 0xff) | (uint256(EXTERNAL_ASSET) << 248));
        assertTrue(config.onlySameFranchise);
        // TODO: test for event

    }

    function test_revert_IfMasksNotConfigured() public {
        IPAsset[] memory sourceIpAssets = new IPAsset[](1);
        sourceIpAssets[0] = IPAsset.UNDEFINED;
        IPAsset[] memory destIpAssets = new IPAsset[](2);

        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIpAssets: sourceIpAssets,
            allowedExternalSource: false,
            destIpAssets: destIpAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });

        vm.expectRevert();
        relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
    }

    function test_relationshipConfigDecoded() public {
        IPAsset[] memory sourceIpAssets = new IPAsset[](1);
        sourceIpAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIpAssets = new IPAsset[](2);
        destIpAssets[0] = IPAsset.CHARACTER;
        destIpAssets[1] = IPAsset.ART;
        
        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIpAssets: sourceIpAssets,
            allowedExternalSource: false,
            destIpAssets: destIpAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });
        bytes32 relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);

        IRelationshipModule.SetRelationshipConfigParams memory result = relationshipModule.getRelationshipConfigDecoded(relId);

        _assertEqIPAssetArray(result.sourceIpAssets, params.sourceIpAssets);
        _assertEqIPAssetArray(result.destIpAssets, params.destIpAssets);
        assertEq(result.allowedExternalSource, params.allowedExternalSource);
        assertEq(result.allowedExternalDest, params.allowedExternalDest);
        assertEq(result.onlySameFranchise, params.onlySameFranchise);
        assertEq(result.processor, params.processor);
        assertEq(result.disputer, params.disputer);
        assertEq(result.timeConfig.minTtl, params.timeConfig.minTtl);
        assertEq(result.timeConfig.maxTtl, params.timeConfig.maxTtl);
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
        IPAsset[] memory sourceIpAssets = new IPAsset[](1);
        sourceIpAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIpAssets = new IPAsset[](1);
        destIpAssets[0] = IPAsset.CHARACTER;
        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIpAssets: sourceIpAssets,
            allowedExternalSource: false,
            destIpAssets: destIpAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });
        relationshipId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
    }

    function test_unsetRelationshipConfig() public {
        relationshipModule.unsetRelationshipConfig(relationshipId);

        IRelationshipModule.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relationshipId);
        assertEq(config.sourceIpAssetTypeMask, 0);
        assertEq(config.destIpAssetTypeMask, 0);
        assertFalse(config.onlySameFranchise);
        // TODO: test for event
    }

    function test_revert_unsetRelationshipConfigNonExistingRelationship() public {
        bytes32 id = relationshipModule.getRelationshipId("UNDEFINED_Relationship");
        vm.expectRevert(IRelationshipModule.NonExistingRelationship.selector);
        relationshipModule.unsetRelationshipConfig(id);
    }

}
