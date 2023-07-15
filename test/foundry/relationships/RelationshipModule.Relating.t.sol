// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/ProxyHelper.sol';
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/access-control/ProtocolRoles.sol";
import "contracts/ip-assets/IPAssetRegistryFactory.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/IPAsset.sol";
import "contracts/errors/General.sol";
import "contracts/modules/relationships/RelationshipProcessors/PermissionlessRelationshipProcessor.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockExternalAsset is ERC721 {
    constructor() ERC721("MockExternalAsset", "MEA") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract RelationshipModuleRelationshipTest is Test, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    FranchiseRegistry public register;
    RelationshipModule public relationshipModule;
    AccessControlSingleton acs;
    PermissionlessRelationshipProcessor public processor;

    address admin = address(123);
    address relationshipManager = address(234);
    address franchiseOwner = address(456);
    address ipAssetOwner = address(567);

    bytes32 relationship = keccak256("RELATIONSHIP");

    mapping(uint8 => uint256) public ipAssetIds;

    MockExternalAsset public externalAsset;


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
        acs.grantRole(RELATIONSHIP_MANAGER_ROLE, relationshipManager);
        
        FranchiseRegistry impl = new FranchiseRegistry(address(factory));
        register = FranchiseRegistry(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(acs)
                )
            )
        );
        vm.prank(franchiseOwner);
        (uint256 id, address ipAssets) = register.registerFranchise("name", "symbol", "description");
        ipAssetRegistry = IPAssetRegistry(ipAssets);

        relationshipModule = RelationshipModule(
            _deployUUPSProxy(
                address(new RelationshipModule(address(register))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(acs)
                )
            )
        );
        IPAsset[] memory sourceIPAssets = new IPAsset[](1);
        sourceIPAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIPAssets = new IPAsset[](2);
        destIPAssets[0] = IPAsset.CHARACTER;
        destIPAssets[1] = IPAsset.ART;

        processor = new PermissionlessRelationshipProcessor(address(relationshipModule));
        RelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: address(processor),
            timeConfig: IRelationshipModule.TimeConfig(0, 0, false)
        });
        vm.prank(relationshipManager);
        relationshipModule.setRelationshipConfig(relationship, params);
        vm.startPrank(ipAssetOwner);

        ipAssetIds[uint8(IPAsset.STORY)] = ipAssetRegistry.createIPAsset(IPAsset.STORY, "name", "description", "mediaUrl");
        ipAssetIds[uint8(IPAsset.CHARACTER)] = ipAssetRegistry.createIPAsset(IPAsset.CHARACTER, "name", "description", "mediaUrl");
        ipAssetIds[uint8(IPAsset.ART)] = ipAssetRegistry.createIPAsset(IPAsset.ART, "name", "description", "mediaUrl");

        externalAsset = new MockExternalAsset();
        ipAssetIds[EXTERNAL_ASSET] = 333;
        externalAsset.mint(ipAssetOwner, 333);
        vm.stopPrank();
    }

    function test_relate() public {
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], relationship, 0
            ),
            ""
        );
        assertTrue(
            relationshipModule.areTheyRelated(
                IRelationshipModule.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], relationship, 0
                )
            )
        );

        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.ART)], relationship, 0
            ),
            ""
        );
        assertTrue(
            relationshipModule.areTheyRelated(
                IRelationshipModule.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.ART)], relationship, 0
                )
            )
        );
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(externalAsset), ipAssetIds[EXTERNAL_ASSET], relationship, 0
            ),
            ""
        );
        assertTrue(
            relationshipModule.areTheyRelated(
                IRelationshipModule.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(externalAsset), ipAssetIds[EXTERNAL_ASSET], relationship, 0
                )
            )
        );
        // TODO check for event
        assertFalse(
            relationshipModule.areTheyRelated(
                IRelationshipModule.RelationshipParams(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(1), 2, relationship, 0)
            )
        );
        assertFalse(
            relationshipModule.areTheyRelated(
                IRelationshipModule.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(externalAsset), ipAssetIds[EXTERNAL_ASSET],  keccak256("WRONG"), 0
                )
            )
        );
    }

    function test_revert_unknown_relationship() public {
        vm.expectRevert(IRelationshipModule.NonExistingRelationship.selector);
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], keccak256("WRONG"), 0
            ),
            ""
        );
    }

    function test_revert_relationshipsNotSameFranchise() public {
        vm.prank(franchiseOwner);
        (uint256 id, address otherIPAssets) = register.registerFranchise("name2", "symbol2", "description2");
        IPAssetRegistry otherIPAssetRegistry = IPAssetRegistry(otherIPAssets);
        vm.prank(ipAssetOwner);
        uint256 otherId = otherIPAssetRegistry.createIPAsset(IPAsset.CHARACTER, "name", "description", "mediaUrl");
        vm.expectRevert(IRelationshipModule.CannotRelationshipToAnotherFranchise.selector);
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], otherIPAssets, otherId, relationship, 0
            ),
            ""
        );
    }

    function test_revert_relateUnsupportedSource() public {
        vm.prank(ipAssetOwner);
        uint256 wrongId = ipAssetRegistry.createIPAsset(IPAsset.GROUP, "name", "description", "mediaUrl");
        vm.expectRevert(IRelationshipModule.UnsupportedRelationshipSource.selector);
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), wrongId, address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], relationship, 0
            ),
            ""
        );
    }

    function test_revert_relateUnsupportedDestination() public {
        vm.prank(ipAssetOwner);
        uint256 wrongId = ipAssetRegistry.createIPAsset(IPAsset.GROUP, "name", "description", "mediaUrl");
        vm.expectRevert(IRelationshipModule.UnsupportedRelationshipDestination.selector);
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), wrongId, relationship, 0
            ),
            ""
        );
    }


}
