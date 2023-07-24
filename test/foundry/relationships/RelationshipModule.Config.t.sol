// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/ProxyHelper.sol';
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/access-control/ProtocolRoles.sol";
import "contracts/ip-assets/IPAssetRegistryFactory.sol";
import "./RelationshipModuleHarness.sol";
import "contracts/IPAsset.sol";
import "contracts/errors/General.sol";
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";

contract RelationshipModuleSetupRelationshipsTest is Test, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    FranchiseRegistry public register;
    RelationshipModuleHarness public relationshipModule;
    AccessControlSingleton acs;
    PermissionlessRelationshipProcessor public RelationshipProcessor;

    address admin = address(123);
    address relationshipManager = address(234);
    address franchiseOwner = address(456);

    bytes32 relationship = keccak256("RELATIONSHIP");

    function setUp() public {
        factory = new IPAssetRegistryFactory();
        acs = AccessControlSingleton(
            _deployUUPSProxy(
                address(new AccessControlSingleton()),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), admin
                )
            )
        );
        vm.prank(admin);
        address accessControl = address(acs);
        
        FranchiseRegistry impl = new FranchiseRegistry(address(factory));
        register = FranchiseRegistry(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), accessControl
                )
            )
        );
        vm.startPrank(franchiseOwner);
        (uint256 id, address ipAssets) = register.registerFranchise("name", "symbol", "description");
        ipAssetRegistry = IPAssetRegistry(ipAssets);
        vm.stopPrank();
        relationshipModule = RelationshipModuleHarness(
            _deployUUPSProxy(
                address(new RelationshipModuleHarness(address(register))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(acs)
                )
            )
        );
        RelationshipProcessor = new PermissionlessRelationshipProcessor(address(relationshipModule));
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
            processor: address(RelationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTTL: 0,
                maxTTL: 0,
                renewable: false
            })
        });
        vm.prank(relationshipManager);
        relationshipModule.setRelationshipConfig(relationship, params);

        IRelationshipModule.RelationshipConfig memory config = relationshipModule.relationshipConfig(relationship);
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
            processor: address(RelationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTTL: 0,
                maxTTL: 0,
                renewable: false
            })
        });
        vm.startPrank(relationshipManager);
        vm.expectRevert();
        relationshipModule.setRelationshipConfig(relationship, params);
    }

}

contract RelationshipModuleUnsetRelationshipsTest is Test, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    FranchiseRegistry public register;
    RelationshipModuleHarness public relationshipModule;
    AccessControlSingleton acs;
    PermissionlessRelationshipProcessor public RelationshipProcessor;

    address admin = address(123);
    address relationshipManager = address(234);
    address franchiseOwner = address(456);

    bytes32 relationship = keccak256("PROTOCOL_Relationship");

    function setUp() public {
        factory = new IPAssetRegistryFactory();
        acs = AccessControlSingleton(
            _deployUUPSProxy(
                address(new AccessControlSingleton()),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), admin
                )
            )
        );
        vm.prank(admin);

        address accessControl = address(acs);
        
        FranchiseRegistry impl = new FranchiseRegistry(address(factory));
        register = FranchiseRegistry(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), accessControl
                )
            )
        );
        vm.startPrank(franchiseOwner);
        (uint256 id, address ipAssets) = register.registerFranchise("name", "symbol", "description");
        ipAssetRegistry = IPAssetRegistry(ipAssets);
        vm.stopPrank();
        relationshipModule = RelationshipModuleHarness(
            _deployUUPSProxy(
                address(new RelationshipModuleHarness(address(register))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(acs)
                )
            )
        );
        RelationshipProcessor = new PermissionlessRelationshipProcessor(address(relationshipModule));
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
            processor: address(RelationshipProcessor),
            disputer: address(this),
            timeConfig: IRelationshipModule.TimeConfig({
                minTTL: 0,
                maxTTL: 0,
                renewable: false
            })
        });
        vm.prank(relationshipManager);
        relationshipModule.setRelationshipConfig(relationship, params);
        
    }

    function test_unsetRelationshipConfig() public {
        vm.prank(relationshipManager);
        relationshipModule.unsetRelationshipConfig(relationship);

        IRelationshipModule.RelationshipConfig memory config = relationshipModule.relationshipConfig(relationship);
        assertEq(config.sourceIPAssetTypeMask, 0);
        assertEq(config.destIPAssetTypeMask, 0);
        assertFalse(config.onlySameFranchise);
        // TODO: test for event
    }

    function test_revert_unsetRelationshipConfigNonExistingRelationship() public {
        vm.prank(relationshipManager);
        vm.expectRevert(IRelationshipModule.NonExistingRelationship.selector);
        relationshipModule.unsetRelationshipConfig(keccak256("UNDEFINED_Relationship"));
    }

}
