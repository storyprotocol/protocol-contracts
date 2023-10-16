// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/ProxyHelper.sol';
import '../utils/BaseTest.sol';
import "../mocks/MockLicensingModule.sol";
import "contracts/lib/IPAsset.sol";
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "contracts/ip-assets/IPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";

contract MockExternalAsset is ERC721 {
    constructor() ERC721("MockExternalAsset", "MEA") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract RelationshipModuleRelationshipTest is BaseTest {


    bytes32 relationshipId;
    address ipAssetOwner = address(567);
    mapping(uint8 => uint256) public ipAssetIds;

    MockExternalAsset public externalAsset;

    function setUp() override public {
        deployProcessors = true;
        super.setUp();
      
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
            onlySameFranchise: true,
            processor: address(relationshipProcessor),
            disputer: address(this),
            timeConfig: Relationship.TimeConfig(0, 0, false)
        });
        
        relationshipId = relationshipModule.setRelationshipConfig("RELATIONSHIP_ID", params);
        vm.startPrank(address(franchiseRegistry));
        ipAssetIds[uint8(IPAsset.IPAssetType.STORY)] = ipAssetRegistry.createIpAsset(IPAsset.IPAssetType.STORY, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)] = ipAssetRegistry.createIpAsset(IPAsset.IPAssetType.CHARACTER, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        ipAssetIds[uint8(IPAsset.IPAssetType.ART)] = ipAssetRegistry.createIpAsset(IPAsset.IPAssetType.ART, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        vm.stopPrank();

        vm.startPrank(ipAssetOwner);
        externalAsset = new MockExternalAsset();
        ipAssetIds[IPAsset.EXTERNAL_ASSET] = 333;
        externalAsset.mint(ipAssetOwner, 333);
        vm.stopPrank();
    }

    function test_relate() public {
        relationshipModule.relate(
            Relationship.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
            ),
            ""
        );
        assertTrue(
            relationshipModule.areTheyRelated(
                Relationship.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
                )
            )
        );
        
        relationshipModule.relate(
            Relationship.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.ART)], relationshipId, 0
            ),
            ""
        );
        assertTrue(
            relationshipModule.areTheyRelated(
                Relationship.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.ART)], relationshipId, 0
                )
            )
        );

        relationshipModule.relate(
            Relationship.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(externalAsset), ipAssetIds[IPAsset.EXTERNAL_ASSET], relationshipId, 0
            ),
            ""
        );
        assertTrue(
            relationshipModule.areTheyRelated(
                Relationship.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(externalAsset), ipAssetIds[IPAsset.EXTERNAL_ASSET], relationshipId, 0
                )
            )
        );
        // TODO check for event
        
    }

    function test_not_related() public {
        assertFalse(
            relationshipModule.areTheyRelated(
                Relationship.RelationshipParams(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(1), 2, relationshipId, 0)
            )
        );
        assertFalse(
            relationshipModule.areTheyRelated(
                Relationship.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(externalAsset), ipAssetIds[IPAsset.EXTERNAL_ASSET],  keccak256("WRONG"), 0
                )
            )
        );
    }

    function test_revert_unknown_relationship() public {
        vm.expectRevert(Errors.RelationshipModule_NonExistingRelationship.selector);
        relationshipModule.relate(
            Relationship.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], keccak256("WRONG"), 0
            ),
            ""
        );
    }

    function test_revert_relationshipsNotSameFranchise() public {
        vm.startPrank(franchiseOwner);
        FranchiseRegistry.FranchiseCreationParams memory params = FranchiseRegistry.FranchiseCreationParams("name2", "symbol2", "description2", "tokenURI2"); 
        (uint256 id, address otherIPAssets) = franchiseRegistry.registerFranchise(params);
        licensingModule.configureFranchiseLicensing(id, LibMockFranchiseConfig.getMockFranchiseConfig());
        vm.stopPrank();
        IPAssetRegistry otherIPAssetRegistry = IPAssetRegistry(otherIPAssets);
        vm.prank(address(franchiseRegistry));
        uint256 otherId = otherIPAssetRegistry.createIpAsset(IPAsset.IPAssetType.CHARACTER, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        vm.expectRevert(Errors.RelationshipModule_CannotRelateToOtherFranchise.selector);
        relationshipModule.relate(
            Relationship.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], otherIPAssets, otherId, relationshipId, 0
            ),
            ""
        );
    }

    function test_revert_relateUnsupportedSource() public {
        vm.prank(address(franchiseRegistry));
        uint256 wrongId = ipAssetRegistry.createIpAsset(IPAsset.IPAssetType.GROUP, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        vm.expectRevert(Errors.RelationshipModule_UnsupportedRelationshipSrc.selector);
        relationshipModule.relate(
            Relationship.RelationshipParams(
                address(ipAssetRegistry), wrongId, address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
            ),
            ""
        );
    }

    function test_revert_relateUnsupportedDestination() public {
        vm.prank(address(franchiseRegistry));
        uint256 wrongId = ipAssetRegistry.createIpAsset(IPAsset.IPAssetType.GROUP, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        vm.expectRevert(Errors.RelationshipModule_UnsupportedRelationshipDst.selector);
        relationshipModule.relate(
            Relationship.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.STORY)], address(ipAssetRegistry), wrongId, relationshipId, 0
            ),
            ""
        );
    }

    function test_revert_nonExistingToken() public {
        vm.expectRevert("ERC721: invalid token ID");
        relationshipModule.relate(
            Relationship.RelationshipParams(
                address(ipAssetRegistry), 420, address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
            ),
            ""
        );
    }

    function test_revert_notERC721() public {
        vm.expectRevert();
        relationshipModule.relate(
            Relationship.RelationshipParams(
                address(0x999), 420, address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.IPAssetType.CHARACTER)], relationshipId, 0
            ),
            ""
        );
    }

}
