// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/ProxyHelper.sol';
import '../utils/BaseTest.sol';
import "../mocks/MockLicensingModule.sol";
import "contracts/IPAsset.sol";
import "contracts/errors/General.sol";
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "contracts/ip-assets/IPAssetRegistry.sol";

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
            timeConfig: IRelationshipModule.TimeConfig(0, 0, false)
        });
        
        relationshipId = relationshipModule.setRelationshipConfig("RELATIONSHIP_ID", params);
        vm.startPrank(address(franchiseRegistry));
        ipAssetIds[uint8(IPAsset.STORY)] = ipAssetRegistry.createIpAsset(IPAsset.STORY, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        ipAssetIds[uint8(IPAsset.CHARACTER)] = ipAssetRegistry.createIpAsset(IPAsset.CHARACTER, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        ipAssetIds[uint8(IPAsset.ART)] = ipAssetRegistry.createIpAsset(IPAsset.ART, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        vm.stopPrank();

        vm.startPrank(ipAssetOwner);
        externalAsset = new MockExternalAsset();
        ipAssetIds[EXTERNAL_ASSET] = 333;
        externalAsset.mint(ipAssetOwner, 333);
        vm.stopPrank();
    }

    function test_relate() public {
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], relationshipId, 0
            ),
            ""
        );
        assertTrue(
            relationshipModule.areTheyRelated(
                IRelationshipModule.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], relationshipId, 0
                )
            )
        );
        
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.ART)], relationshipId, 0
            ),
            ""
        );
        assertTrue(
            relationshipModule.areTheyRelated(
                IRelationshipModule.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.ART)], relationshipId, 0
                )
            )
        );

        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(externalAsset), ipAssetIds[EXTERNAL_ASSET], relationshipId, 0
            ),
            ""
        );
        assertTrue(
            relationshipModule.areTheyRelated(
                IRelationshipModule.RelationshipParams(
                    address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(externalAsset), ipAssetIds[EXTERNAL_ASSET], relationshipId, 0
                )
            )
        );
        // TODO check for event
        
    }

    function test_not_related() public {
        assertFalse(
            relationshipModule.areTheyRelated(
                IRelationshipModule.RelationshipParams(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(1), 2, relationshipId, 0)
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
        vm.startPrank(franchiseOwner);
        FranchiseRegistry.FranchiseCreationParams memory params = FranchiseRegistry.FranchiseCreationParams("name2", "symbol2", "description2", "tokenURI2"); 
        (uint256 id, address otherIPAssets) = franchiseRegistry.registerFranchise(params);
        licensingModule.configureFranchiseLicensing(id, LibMockFranchiseConfig.getMockFranchiseConfig());
        vm.stopPrank();
        IPAssetRegistry otherIPAssetRegistry = IPAssetRegistry(otherIPAssets);
        vm.prank(address(franchiseRegistry));
        uint256 otherId = otherIPAssetRegistry.createIpAsset(IPAsset.CHARACTER, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        vm.expectRevert(IRelationshipModule.CannotRelateToOtherFranchise.selector);
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], otherIPAssets, otherId, relationshipId, 0
            ),
            ""
        );
    }

    function test_revert_relateUnsupportedSource() public {
        vm.prank(address(franchiseRegistry));
        uint256 wrongId = ipAssetRegistry.createIpAsset(IPAsset.GROUP, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        vm.expectRevert(IRelationshipModule.UnsupportedRelationshipSrc.selector);
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), wrongId, address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], relationshipId, 0
            ),
            ""
        );
    }

    function test_revert_relateUnsupportedDestination() public {
        vm.prank(address(franchiseRegistry));
        uint256 wrongId = ipAssetRegistry.createIpAsset(IPAsset.GROUP, "name", "description", "mediaUrl", ipAssetOwner, 0, "");
        vm.expectRevert(IRelationshipModule.UnsupportedRelationshipDst.selector);
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), wrongId, relationshipId, 0
            ),
            ""
        );
    }

    function test_revert_nonExistingToken() public {
        vm.expectRevert("ERC721: invalid token ID");
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(ipAssetRegistry), 420, address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], relationshipId, 0
            ),
            ""
        );
    }

    function test_revert_notERC721() public {
        vm.expectRevert();
        relationshipModule.relate(
            IRelationshipModule.RelationshipParams(
                address(0x999), 420, address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], relationshipId, 0
            ),
            ""
        );
    }

}
