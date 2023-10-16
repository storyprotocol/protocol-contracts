// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/ip-assets/IPAssetGroup.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";

contract ProtocolRelationshipModuleSetupRelationshipsTest is BaseTest {

    address relationshipManager = address(0x234);

    function setUp() override public {
        deployProcessors = true;
        super.setUp();

        vm.startPrank(franchiseOwner);
        IPAsset.RegisterIPAssetGroupParams memory params = IPAsset.RegisterIPAssetGroupParams(
            "name",
            "symbol",
            "description",
            "tokenURI",
            address(licensingModule),
            address(collectModule)
        );
        (uint256 id, address ipAssets) = ipAssetController.registerIPAssetGroup(params);
        ipAssetGroup = IPAssetGroup(ipAssets);
        vm.stopPrank();
        relationshipModule = ProtocolRelationshipModule(
            _deployUUPSProxy(
                address(new ProtocolRelationshipModule(address(ipAssetController))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
        vm.prank(admin);
        accessControl.grantRole(AccessControl.RELATIONSHIP_MANAGER_ROLE, relationshipManager);
    }

    function test_setProtocolLevelRelationship() public {
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
            onlySameIPAssetGroup: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: Relationship.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });
        vm.prank(relationshipManager);
        bytes32 relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);

        Relationship.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relId);
        assertEq(config.sourceIpAssetTypeMask, 1 << (uint256(IPAsset.IPAssetType.STORY) & 0xff));
        assertEq(config.destIpAssetTypeMask, 1 << (uint256(IPAsset.IPAssetType.CHARACTER) & 0xff) | 1 << (uint256(IPAsset.IPAssetType.ART) & 0xff) | (uint256(IPAsset.EXTERNAL_ASSET) << 248));
        assertTrue(config.onlySameIPAssetGroup);
        // TODO: test for event

    }

    function test_revert_IfSettingProtocolLevelRelationshipUnauthorized() public {
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
            onlySameIPAssetGroup: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: Relationship.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });
        vm.expectRevert();
        vm.prank(franchiseOwner);
        relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
    }

}

contract ProtocolRelationshipModuleUnsetRelationshipsTest is BaseTest {

    bytes32 relId;
    address relationshipManager = address(0x234);

    function setUp() override public {
        deployProcessors = true;
        super.setUp();
        relationshipModule = ProtocolRelationshipModule(
            _deployUUPSProxy(
                address(new ProtocolRelationshipModule(address(ipAssetController))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
        vm.prank(admin);
        accessControl.grantRole(AccessControl.RELATIONSHIP_MANAGER_ROLE, relationshipManager);

        IPAsset.IPAssetType[] memory sourceIpAssets = new IPAsset.IPAssetType[](1);
        sourceIpAssets[0] = IPAsset.IPAssetType.STORY;
        IPAsset.IPAssetType[] memory destIpAssets = new IPAsset.IPAssetType[](1);
        destIpAssets[0] = IPAsset.IPAssetType.CHARACTER;
        Relationship.SetRelationshipConfigParams memory params = Relationship.SetRelationshipConfigParams({
            sourceIpAssets: sourceIpAssets,
            allowedExternalSource: false,
            destIpAssets: destIpAssets,
            allowedExternalDest: true,
            onlySameIPAssetGroup: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: Relationship.TimeConfig({
                minTtl: 0,
                maxTtl: 0,
                renewable: false
            })
        });
        vm.prank(relationshipManager);
        relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
        
    }

    function test_unsetRelationshipConfig() public {
        vm.prank(relationshipManager);
        relationshipModule.unsetRelationshipConfig(relId);

        Relationship.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relId);
        assertEq(config.sourceIpAssetTypeMask, 0);
        assertEq(config.destIpAssetTypeMask, 0);
        assertFalse(config.onlySameIPAssetGroup);
        // TODO: test for event
    }

    function test_revert_unsetRelationshipConfigNotAuthorized() public {
        vm.expectRevert();
        vm.prank(franchiseOwner);
        relationshipModule.unsetRelationshipConfig(relId);
    }

}
