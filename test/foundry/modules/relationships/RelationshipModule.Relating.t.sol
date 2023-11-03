// // SPDX-License-Identifier: BUSDL-1.1
// pragma solidity ^0.8.13;

// import "forge-std/Test.sol";
// import 'test/foundry/utils/ProxyHelper.sol';
// import 'test/foundry/utils/BaseTest.sol';
// import "test/foundry/mocks/MockLicensingModule.sol";
// import "contracts/lib/IPAsset.sol";
// import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "contracts/ip-org/IPOrg.sol";

// import { Errors } from "contracts/lib/Errors.sol";
// import { Relationship } from "contracts/lib/modules/Relationship.sol";

// contract MockExternalAsset is ERC721 {
//     constructor() ERC721("MockExternalAsset", "MEA") {}

//     function mint(address to, uint256 tokenId) public {
//         _mint(to, tokenId);
//     }
// }

// contract RelationshipModuleRelationshipTest is BaseTest {


//     bytes32 relationshipId;
//     address ipAssetOwner = address(567);
//     mapping(uint8 => uint256) public ipAssetIds;

//     MockExternalAsset public externalAsset;

//     function setUp() override public {
//         deployProcessors = true;
//         super.setUp();
      
//         IPAsset.IPAssetType[] memory sourceIpAssets = new IPAsset.IPAssetType[](1);
//         sourceIpAssets[0] = IPAsset.IPAssetType.STORY;
//         IPAsset.IPAssetType[] memory destIpAssets = new IPAsset.IPAssetType[](2);
//         destIpAssets[0] = IPAsset.IPAssetType.CHARACTER;
//         destIpAssets[1] = IPAsset.IPAssetType.ART;

//         Relationship.SetRelationshipConfigParams memory params = Relationship.SetRelationshipConfigParams({
//             sourceIpAssets: sourceIpAssets,
//             allowedExternalSource: false,
//             destIpAssets: destIpAssets,
//             allowedExternalDest: true,
//             onlySameIPOrg: true,
//             processor: address(relationshipProcessor),
//             disputer: address(this),
//             timeConfig: Relationship.TimeConfig(0, 0, false)
//         });
        
//         relationshipId = relationshipModule.setRelationshipConfig("RELATIONSHIP_ID", params);
//         vm.startPrank(address(ipAssetOrgOwner));
//         uint256 orgId;

//         (, orgId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType.STORY,
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetOwner,
//             parentIpOrgId: 0,
//             collectData: ""
//         }));
//         ipAssetIds[uint8(IPAsset.IPAssetType.STORY)] = orgId;

//         (, orgId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType.CHARACTER,
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetOwner,
//             parentIpOrgId: 0,
//             collectData: ""
//         }));
//         ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)] = orgId;

//         (, orgId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType.ART,
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetOwner,
//             parentIpOrgId: 0,
//             collectData: ""
//         }));

//         ipAssetIds[uint8(IPAsset.IPAssetType.ART)] = orgId;
//         vm.stopPrank();

//         vm.startPrank(ipAssetOwner);
//         externalAsset = new MockExternalAsset();
//         ipAssetIds[IPAsset.EXTERNAL_ASSET] = 333;
//         externalAsset.mint(ipAssetOwner, 333);
//         vm.stopPrank();
//     }

//     function test_relate() public {
//         relationshipModule.relate(
//             Relationship.RelationshipParams(
//                 address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
//             ),
//             ""
//         );
//         assertTrue(
//             relationshipModule.areTheyRelated(
//                 Relationship.RelationshipParams(
//                     address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
//                 )
//             )
//         );
        
//         relationshipModule.relate(
//             Relationship.RelationshipParams(
//                 address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.ART)], relationshipId, 0
//             ),
//             ""
//         );
//         assertTrue(
//             relationshipModule.areTheyRelated(
//                 Relationship.RelationshipParams(
//                     address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.ART)], relationshipId, 0
//                 )
//             )
//         );

//         relationshipModule.relate(
//             Relationship.RelationshipParams(
//                 address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(externalAsset), ipAssetIds[IPAsset.EXTERNAL_ASSET], relationshipId, 0
//             ),
//             ""
//         );
//         assertTrue(
//             relationshipModule.areTheyRelated(
//                 Relationship.RelationshipParams(
//                     address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(externalAsset), ipAssetIds[IPAsset.EXTERNAL_ASSET], relationshipId, 0
//                 )
//             )
//         );
//         // TODO check for event
        
//     }

//     function test_not_related() public {
//         assertFalse(
//             relationshipModule.areTheyRelated(
//                 Relationship.RelationshipParams(address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(1), 2, relationshipId, 0)
//             )
//         );
//         assertFalse(
//             relationshipModule.areTheyRelated(
//                 Relationship.RelationshipParams(
//                     address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(externalAsset), ipAssetIds[IPAsset.EXTERNAL_ASSET],  keccak256("WRONG"), 0
//                 )
//             )
//         );
//     }

//     function test_revert_unknown_relationship() public {
//         vm.expectRevert(Errors.RelationshipModule_NonExistingRelationship.selector);
//         relationshipModule.relate(
//             Relationship.RelationshipParams(
//                 address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], keccak256("WRONG"), 0
//             ),
//             ""
//         );
//     }

//     // TODO(ramarti): Fix this test
//     // function test_revert_relationshipsNotSameIPOrg() public {
//     //     vm.startPrank(ipAssetOrgOwner);
//     //     IPAsset.RegisterIPOrgParams memory params = IPAsset.RegisterIPOrgParams(address(registry), "name2", "symbol2", "description2", "tokenURI2", address(licensingModule), address(collectModule)); 
//     //     address otherIpAssets = ipAssetOrgFactory.registerIpOrg(params);
//     //     licensingModule.configureIpOrgLicensing(otherIpAssets, LibMockIPOrgConfig.getMockIPOrgConfig());
//     //     vm.stopPrank();
//     //     IPOrg otherIpOrg = IPOrg(otherIpAssets);
//     //     vm.prank(address(ipAssetOrgOwner));
//     //     (, uint256 otherId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//     //         ipAssetType: IPAsset.IPAssetType.CHARACTER,
//     //         name: "name",
//     //         description: "description",
//     //         mediaUrl: "mediaUrl",
//     //         to: ipAssetOwner,
//     //         parentIpOrgId: 0,
//     //         collectData: ""
//     //     }));
//     //     vm.expectRevert(Errors.RelationshipModule_CannotRelateToOtherIPOrg.selector);
//     //     relationshipModule.relate(
//     //         Relationship.RelationshipParams(
//     //             address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], otherIpAssets, otherId, relationshipId, 0
//     //         ),
//     //         ""
//     //     );
//     // }

//     function test_revert_relateUnsupportedSource() public {
//         vm.prank(address(ipAssetOrgOwner));
//         (, uint256 wrongId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType.GROUP,
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetOwner,
//             parentIpOrgId: 0,
//             collectData: ""
//         }));
//         vm.expectRevert(Errors.RelationshipModule_UnsupportedRelationshipSrc.selector);
//         relationshipModule.relate(
//             Relationship.RelationshipParams(
//                 address(ipAssetOrg), wrongId, address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
//             ),
//             ""
//         );
//     }

//     function test_revert_relateUnsupportedDestination() public {
//         vm.prank(address(ipAssetOrgOwner));
//         (, uint256 wrongId) = ipAssetOrg.createIpAsset(IPAsset.CreateIpAssetParams({
//             ipAssetType: IPAsset.IPAssetType.GROUP,
//             name: "name",
//             description: "description",
//             mediaUrl: "mediaUrl",
//             to: ipAssetOwner,
//             parentIpOrgId: 0,
//             collectData: ""
//         }));
//         vm.expectRevert(Errors.RelationshipModule_UnsupportedRelationshipDst.selector);
//         relationshipModule.relate(
//             Relationship.RelationshipParams(
//                 address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetOrg), wrongId, relationshipId, 0
//             ),
//             ""
//         );
//     }

//     function test_revert_nonExistingToken() public {
//         vm.expectRevert("ERC721: invalid token ID");
//         relationshipModule.relate(
//             Relationship.RelationshipParams(
//                 address(ipAssetOrg), 420, address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
//             ),
//             ""
//         );
//     }

//     function test_revert_notERC721() public {
//         vm.expectRevert();
//         relationshipModule.relate(
//             Relationship.RelationshipParams(
//                 address(0x999), 420, address(ipAssetOrg), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
//             ),
//             ""
//         );
//     }

// }
