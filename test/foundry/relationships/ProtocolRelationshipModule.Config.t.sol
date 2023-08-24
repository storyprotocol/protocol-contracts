// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/BaseTest.sol';
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/access-control/ProtocolRoles.sol";
import "contracts/ip-assets/events/CommonIPAssetEventEmitter.sol";
import "contracts/ip-assets/IPAssetRegistry.sol";
import "contracts/libraries/DataTypes.sol";

contract ProtocolRelationshipModuleSetupRelationshipsTest is BaseTest {

    address relationshipManager = address(0x234);

    function setUp() override public {
        deployProcessors = true;
        super.setUp();

        vm.startPrank(franchiseOwner);
        DataTypes.FranchiseCreationParams memory params = DataTypes.FranchiseCreationParams("name", "symbol", "description", "tokenURI", address(0));
        (uint256 id, address ipAssets) = franchiseRegistry.registerFranchise(params);
        ipAssetRegistry = IPAssetRegistry(ipAssets);
        vm.stopPrank();
        relationshipModule = ProtocolRelationshipModule(
            _deployUUPSProxy(
                address(new ProtocolRelationshipModule(address(franchiseRegistry))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
        vm.prank(admin);
        accessControl.grantRole(RELATIONSHIP_MANAGER_ROLE, relationshipManager);
    }

    function test_setProtocolLevelRelationship() public {
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
        vm.prank(relationshipManager);
        bytes32 relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);

        IRelationshipModule.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relId);
        assertEq(config.sourceIPAssetTypeMask, 1 << (uint256(IPAsset.STORY) & 0xff));
        assertEq(config.destIPAssetTypeMask, 1 << (uint256(IPAsset.CHARACTER) & 0xff) | 1 << (uint256(IPAsset.ART) & 0xff) | (uint256(EXTERNAL_ASSET) << 248));
        assertTrue(config.onlySameFranchise);
        // TODO: test for event

    }

    function test_revert_IfSettingProtocolLevelRelationshipUnauthorized() public {
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
                address(new ProtocolRelationshipModule(address(franchiseRegistry))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
        vm.prank(admin);
        accessControl.grantRole(RELATIONSHIP_MANAGER_ROLE, relationshipManager);

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
        vm.prank(relationshipManager);
        relId = relationshipModule.setRelationshipConfig("RELATIONSHIP", params);
        
    }

    function test_unsetRelationshipConfig() public {
        vm.prank(relationshipManager);
        relationshipModule.unsetRelationshipConfig(relId);

        IRelationshipModule.RelationshipConfig memory config = relationshipModule.getRelationshipConfig(relId);
        assertEq(config.sourceIPAssetTypeMask, 0);
        assertEq(config.destIPAssetTypeMask, 0);
        assertFalse(config.onlySameFranchise);
        // TODO: test for event
    }

    function test_revert_unsetRelationshipConfigNotAuthorized() public {
        vm.expectRevert();
        vm.prank(franchiseOwner);
        relationshipModule.unsetRelationshipConfig(relId);
    }

}
