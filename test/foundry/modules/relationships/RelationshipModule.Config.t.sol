// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import 'test/foundry/utils/BaseTest.sol';
import { Errors } from "contracts/lib/Errors.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";

contract RelationshipModuleSetupRelationshipsTest is BaseTest {

    function setUp() virtual override public {
        deployProcessors = true;
        super.setUp();
    }

    function test_setRelationship() public {
        IPAsset.IPAssetType[] memory sourceIpAssets = new IPAsset.IPAssetType[](1);
        sourceIpAssets[0] = IPAsset.IPAssetType.STORY;
        IPAsset.IPAssetType[] memory destIpAssets = new IPAsset.IPAssetType[](2);
        destIpAssets[0] = IPAsset.IPAssetType.CHARACTER;
        destIpAssets[1] = IPAsset.IPAssetType.ART;
        
        Relationship.SetRelationshipConfigParams memory params = Relationship.SetRelationshipConfigParams({
            sourceIpAssets: sourceIpAssets,
            allowedExternalSource: false,
            destIpAssets: destIpAssets,
            allowedExternalDest: true,
            onlySameIPOrg: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: Relationship.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });

        bytes32 relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
        assertEq(relId, keccak256(abi.encode("RELATIONSHIP")));

        Relationship.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relId);
        assertEq(config.sourceIpAssetTypeMask, 1 << (uint256(IPAsset.IPAssetType.STORY) & 0xff));
        assertEq(config.destIpAssetTypeMask, 1 << (uint256(IPAsset.IPAssetType.CHARACTER) & 0xff) | 1 << (uint256(IPAsset.IPAssetType.ART) & 0xff) | (uint256(IPAsset.EXTERNAL_ASSET) << 248));
        assertTrue(config.onlySameIPOrg);
        // TODO: test for event

    }

    function test_revert_IfMasksNotConfigured() public {
        IPAsset.IPAssetType[] memory sourceIpAssets = new IPAsset.IPAssetType[](1);
        sourceIpAssets[0] = IPAsset.IPAssetType.UNDEFINED;
        IPAsset.IPAssetType[] memory destIpAssets = new IPAsset.IPAssetType[](2);

        Relationship.SetRelationshipConfigParams memory params = Relationship.SetRelationshipConfigParams({
            sourceIpAssets: sourceIpAssets,
            allowedExternalSource: false,
            destIpAssets: destIpAssets,
            allowedExternalDest: true,
            onlySameIPOrg: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: Relationship.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });

        vm.expectRevert();
        relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
    }

    function test_relationshipConfigDecoded() public {
        IPAsset.IPAssetType[] memory sourceIpAssets = new IPAsset.IPAssetType[](1);
        sourceIpAssets[0] = IPAsset.IPAssetType.STORY;
        IPAsset.IPAssetType[] memory destIpAssets = new IPAsset.IPAssetType[](2);
        destIpAssets[0] = IPAsset.IPAssetType.CHARACTER;
        destIpAssets[1] = IPAsset.IPAssetType.ART;
        
        Relationship.SetRelationshipConfigParams memory params = Relationship.SetRelationshipConfigParams({
            sourceIpAssets: sourceIpAssets,
            allowedExternalSource: false,
            destIpAssets: destIpAssets,
            allowedExternalDest: true,
            onlySameIPOrg: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: Relationship.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });
        bytes32 relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);

        Relationship.SetRelationshipConfigParams memory result = relationshipModule.getRelationshipConfigDecoded(relId);

        _assertEqIPAssetArray(result.sourceIpAssets, params.sourceIpAssets);
        _assertEqIPAssetArray(result.destIpAssets, params.destIpAssets);
        assertEq(result.allowedExternalSource, params.allowedExternalSource);
        assertEq(result.allowedExternalDest, params.allowedExternalDest);
        assertEq(result.onlySameIPOrg, params.onlySameIPOrg);
        assertEq(result.processor, params.processor);
        assertEq(result.disputer, params.disputer);
        assertEq(result.timeConfig.minTtl, params.timeConfig.minTtl);
        assertEq(result.timeConfig.maxTtl, params.timeConfig.maxTtl);
        assertEq(result.timeConfig.renewable, params.timeConfig.renewable);

    }

    function _assertEqIPAssetArray(IPAsset.IPAssetType[] memory result, IPAsset.IPAssetType[] memory expected) internal {
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
        IPAsset.IPAssetType[] memory sourceIpAssets = new IPAsset.IPAssetType[](1);
        sourceIpAssets[0] = IPAsset.IPAssetType.STORY;
        IPAsset.IPAssetType[] memory destIpAssets = new IPAsset.IPAssetType[](1);
        destIpAssets[0] = IPAsset.IPAssetType.CHARACTER;
        Relationship.SetRelationshipConfigParams memory params = Relationship.SetRelationshipConfigParams({
            sourceIpAssets: sourceIpAssets,
            allowedExternalSource: false,
            destIpAssets: destIpAssets,
            allowedExternalDest: true,
            onlySameIPOrg: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: Relationship.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });
        relationshipId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
    }

    function test_unsetRelationshipConfig() public {
        relationshipModule.unsetRelationshipConfig(relationshipId);

        Relationship.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relationshipId);
        assertEq(config.sourceIpAssetTypeMask, 0);
        assertEq(config.destIpAssetTypeMask, 0);
        assertFalse(config.onlySameIPOrg);
        // TODO: test for event
    }

    function test_revert_unsetRelationshipConfigNonExistingRelationship() public {
        bytes32 id = relationshipModule.getRelationshipId("UNDEFINED_Relationship");
        vm.expectRevert(Errors.RelationshipModule_NonExistingRelationship.selector);
        relationshipModule.unsetRelationshipConfig(id);
    }

}
