// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import 'test/foundry/utils/ProxyHelper.sol';
import 'test/foundry/utils/BaseTestUtils.sol';
import "test/foundry/mocks/RelationshipModuleHarness.sol";
import "test/foundry/mocks/MockCollectNFT.sol";
import "test/foundry/mocks/MockCollectModule.sol";
import "contracts/FranchiseRegistry.sol";
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
import { ICollectNFT } from "contracts/interfaces/ICollectNFT.sol";
import { ICollectModule } from "contracts/interfaces/ICollectModule.sol";

contract BaseTest is BaseTestUtils, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    uint256 public franchiseId;
    address ipAssetRegistryImpl;
    FranchiseRegistry public franchiseRegistry;
    RelationshipModuleBase public relationshipModule;
    AccessControlSingleton accessControl;
    PermissionlessRelationshipProcessor public relationshipProcessor;
    ICollectModule public collectModule;
    RelationshipModuleHarness public relationshipModuleHarness;
    address eventEmitter;
    address public franchiseRegistryImpl;
    address public defaultCollectNFTImpl;
    address public collectModuleImpl;
    address public accessControlSingletonImpl;

    address admin = address(123);
    address franchiseOwner = address(456);
    bool public deployProcessors = false;

    constructor() {}

    function setUp() virtual override(BaseTestUtils) public {
        super.setUp();
        factory = new IPAssetRegistryFactory();
        accessControlSingletonImpl = address(new AccessControlSingleton());
        accessControl = AccessControlSingleton(
            _deployUUPSProxy(
                accessControlSingletonImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), admin
                )
            )
        );
        
        franchiseRegistryImpl = address(new FranchiseRegistry(address(factory)));
        franchiseRegistry = FranchiseRegistry(
            _deployUUPSProxy(
                franchiseRegistryImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
        eventEmitter = address(new CommonIPAssetEventEmitter(address(franchiseRegistry)));
        ipAssetRegistryImpl = address(new IPAssetRegistry(eventEmitter));
        factory.upgradeFranchises(ipAssetRegistryImpl);

        vm.startPrank(franchiseOwner);
        FranchiseRegistry.FranchiseCreationParams memory params = FranchiseRegistry.FranchiseCreationParams("name", "symbol", "description", "tokenURI");
        (, address ipAssets) = franchiseRegistry.registerFranchise(params);
        ipAssetRegistry = IPAssetRegistry(ipAssets);
        franchiseId = ipAssetRegistry.franchiseId();
        vm.stopPrank();
        relationshipModuleHarness = new RelationshipModuleHarness(address(franchiseRegistry));
        relationshipModule = RelationshipModuleBase(
            _deployUUPSProxy(
                address(relationshipModuleHarness),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );

        // Deploy collect module and collect NFT impl
        defaultCollectNFTImpl = address(new MockCollectNFT());
        collectModuleImpl = address(new MockCollectModule(address(franchiseRegistry), defaultCollectNFTImpl));

        collectModule = ICollectModule(
            _deployUUPSProxy(
                collectModuleImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );

        if (deployProcessors) {
            relationshipProcessor = new PermissionlessRelationshipProcessor(address(relationshipModule));
        }
    }

    /// @dev Helper function for creating an IP asset for an owner and IP type.
    ///      TO-DO: Replace this with a simpler set of default owners that get
    ///      tested against. The reason this is currently added is that during
    ///      fuzz testing, foundry may plug existing contracts as potential
    ///      owners for IP asset creation.
    function _createIPAsset(address ipAssetOwner, uint8 ipAssetType) internal isValidReceiver(ipAssetOwner) returns (uint256) {
        vm.assume(ipAssetType > uint8(type(IPAsset).min));
        vm.assume(ipAssetType < uint8(type(IPAsset).max));
        vm.assume(ipAssetOwner != address(0));
        vm.assume(ipAssetOwner != address(franchiseRegistry));
        vm.assume(ipAssetOwner != address(factory));
        vm.assume(ipAssetOwner != address(relationshipModule));
        vm.assume(ipAssetOwner != address(accessControl));
        vm.assume(ipAssetOwner != address(accessControlSingletonImpl));
        vm.assume(ipAssetOwner != address(collectModule));
        vm.assume(ipAssetOwner != address(collectModuleImpl));
        vm.assume(ipAssetOwner != address(defaultCollectNFTImpl));
        vm.assume(ipAssetOwner != address(franchiseRegistryImpl));
        vm.assume(ipAssetOwner != address(relationshipProcessor));
        vm.assume(ipAssetOwner != address(ipAssetRegistry));
        vm.assume(ipAssetOwner != address(relationshipModuleHarness));
        vm.assume(ipAssetOwner != address(ipAssetRegistryImpl));
        vm.assume(ipAssetOwner != address(eventEmitter));
        vm.prank(ipAssetOwner);
        return ipAssetRegistry.createIPAsset(IPAsset(ipAssetType), "name", "description", "mediaUrl");
    }

}
