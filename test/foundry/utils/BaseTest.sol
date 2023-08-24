// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import 'test/foundry/utils/ProxyHelper.sol';
import "test/foundry/mocks/RelationshipModuleHarness.sol";
import "contracts/FranchiseRegistry.sol";
import "contracts/StoryProtocol.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/access-control/ProtocolRoles.sol";
import "contracts/ip-assets/IPAssetRegistryFactory.sol";
import "contracts/ip-assets/events/CommonIPAssetEventEmitter.sol";
import "contracts/ip-assets/IPAssetRegistry.sol";
import "contracts/IPAsset.sol";
import "contracts/errors/General.sol";
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
import "contracts/modules/relationships/RelationshipModuleBase.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/libraries/DataTypes.sol";

contract BaseTest is Test, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    FranchiseRegistry public franchiseRegistry;
    RelationshipModuleBase public relationshipModule;
    AccessControlSingleton accessControl;
    PermissionlessRelationshipProcessor public relationshipProcessor;
    StoryProtocol public storyProtocol;

    address admin = address(123);
    address franchiseOwner = address(456);
    bool public deployProcessors = false;

    constructor() {}

    function setUp() virtual public {
        factory = new IPAssetRegistryFactory();
        accessControl = AccessControlSingleton(
            _deployUUPSProxy(
                address(new AccessControlSingleton()),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), admin
                )
            )
        );
        
        FranchiseRegistry impl = new FranchiseRegistry(address(factory));
        franchiseRegistry = FranchiseRegistry(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
        address eventEmitter = address(new CommonIPAssetEventEmitter(address(franchiseRegistry)));
        factory.upgradeFranchises(address(new IPAssetRegistry(eventEmitter)));

        StoryProtocol orchestratorImpl = new StoryProtocol(address(franchiseRegistry));
        storyProtocol = StoryProtocol(
            _deployUUPSProxy(
                address(orchestratorImpl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );

        vm.startPrank(franchiseOwner);
        DataTypes.FranchiseCreationParams memory params = DataTypes.FranchiseCreationParams("name", "symbol", "description", "tokenURI", address(0));
        (uint256 id, address ipAssets) = franchiseRegistry.registerFranchise(params);
        ipAssetRegistry = IPAssetRegistry(ipAssets);
        vm.stopPrank();
        relationshipModule = RelationshipModuleBase(
            _deployUUPSProxy(
                address(new RelationshipModuleHarness(address(franchiseRegistry))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );

        if (deployProcessors) {
            relationshipProcessor = new PermissionlessRelationshipProcessor(address(relationshipModule));
        }
    }
}