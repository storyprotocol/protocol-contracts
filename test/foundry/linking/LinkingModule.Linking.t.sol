// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/ProxyHelper.sol';
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/access-control/ProtocolRoles.sol";
import "contracts/ip-assets/IPAssetRegistryFactory.sol";
import "contracts/modules/linking/LinkingModule.sol";
import "contracts/IPAsset.sol";
import "contracts/errors/General.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockExternalAsset is ERC721 {
    constructor() ERC721("MockExternalAsset", "MEA") {}

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}

contract LinkingModuleLinkingTest is Test, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    FranchiseRegistry public register;
    LinkingModule public linkingModule;
    AccessControlSingleton acs;

    address admin = address(123);
    address linkManager = address(234);
    address franchiseOwner = address(456);
    address ipAssetOwner = address(567);

    bytes32 protocolLink = keccak256("PROTOCOL_LINK");

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
        acs.grantRole(LINK_MANAGER_ROLE, linkManager);
        
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

        linkingModule = LinkingModule(
            _deployUUPSProxy(
                address(new LinkingModule(address(register))),
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

        LinkingModule.SetLinkParams memory params = LinkingModule.SetLinkParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            linkOnlySameFranchise: true
        });
        vm.prank(linkManager);
        linkingModule.setProtocolLink(protocolLink, params);
        vm.startPrank(ipAssetOwner);

        ipAssetIds[uint8(IPAsset.STORY)] = ipAssetRegistry.createIPAsset(IPAsset.STORY, "name", "description", "mediaUrl");
        ipAssetIds[uint8(IPAsset.CHARACTER)] = ipAssetRegistry.createIPAsset(IPAsset.CHARACTER, "name", "description", "mediaUrl");
        ipAssetIds[uint8(IPAsset.ART)] = ipAssetRegistry.createIPAsset(IPAsset.ART, "name", "description", "mediaUrl");

        externalAsset = new MockExternalAsset();
        ipAssetIds[EXTERNAL_ASSET] = 333;
        externalAsset.mint(ipAssetOwner, 333);
        vm.stopPrank();
    }

    function test_link() public {
        linkingModule.link(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], protocolLink);
        assertTrue(
            linkingModule.areTheyLinked(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], protocolLink)
        );
        linkingModule.link(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.ART)], protocolLink);
        assertTrue(
            linkingModule.areTheyLinked(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.ART)], protocolLink)
        );
        linkingModule.link(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(externalAsset), ipAssetIds[EXTERNAL_ASSET], protocolLink);
        assertTrue(
            linkingModule.areTheyLinked(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(externalAsset), ipAssetIds[EXTERNAL_ASSET], protocolLink)
        );
        // TODO check for event
        assertFalse(
            linkingModule.areTheyLinked(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(1), 2, protocolLink)
        );
        assertFalse(
            linkingModule.areTheyLinked(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(externalAsset), ipAssetIds[EXTERNAL_ASSET],  keccak256("WRONG_LINK"))
        );
    }

    function test_revert_linkingNotSameFranchise() public {
        vm.prank(franchiseOwner);
        (uint256 id, address otherIPAssets) = register.registerFranchise("name2", "symbol2", "description2");
        IPAssetRegistry otherIPAssetRegistry = IPAssetRegistry(otherIPAssets);
        vm.prank(ipAssetOwner);
        uint256 otherId = otherIPAssetRegistry.createIPAsset(IPAsset.CHARACTER, "name", "description", "mediaUrl");
        vm.expectRevert(LinkingModule.CannotLinkToAnotherFranchise.selector);
        linkingModule.link(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], otherIPAssets, otherId, protocolLink);
    }

    function test_revert_linkUnsupportedSource() public {
        vm.prank(ipAssetOwner);
        uint256 wrongId = ipAssetRegistry.createIPAsset(IPAsset.GROUP, "name", "description", "mediaUrl");
        vm.expectRevert(LinkingModule.UnsupportedLinkSource.selector);
        linkingModule.link(address(ipAssetRegistry), wrongId, address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.CHARACTER)], protocolLink);
    }

    function test_revert_linkUnsupportedDestination() public {
        vm.prank(ipAssetOwner);
        uint256 wrongId = ipAssetRegistry.createIPAsset(IPAsset.GROUP, "name", "description", "mediaUrl");
        vm.expectRevert(LinkingModule.UnsupportedLinkDestination.selector);
        linkingModule.link(address(ipAssetRegistry), ipAssetIds[uint8(IPAsset.STORY)], address(ipAssetRegistry), wrongId, protocolLink);
    }


}
