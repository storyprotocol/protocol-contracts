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
import "contracts/modules/linking/LinkProcessors/PermissionlessLinkProcessor.sol";

contract LinkingModuleSetupLinksTest is Test, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    FranchiseRegistry public register;
    LinkingModule public linkingModule;
    AccessControlSingleton acs;
    PermissionlessLinkProcessor public linkProcessor;

    address admin = address(123);
    address linkManager = address(234);
    address franchiseOwner = address(456);

    bytes32 protocolLink = keccak256("PROTOCOL_LINK");

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
        linkingModule = LinkingModule(
            _deployUUPSProxy(
                address(new LinkingModule(address(register))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(acs)
                )
            )
        );
        linkProcessor = new PermissionlessLinkProcessor(address(linkingModule));
    }

    function test_setProtocolLevelLink() public {
        IPAsset[] memory sourceIPAssets = new IPAsset[](1);
        sourceIPAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIPAssets = new IPAsset[](2);
        destIPAssets[0] = IPAsset.CHARACTER;
        destIPAssets[1] = IPAsset.ART;
        
        LinkingModule.SetLinkParams memory params = ILinkingModule.SetLinkParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            linkOnlySameFranchise: true,
            linkProcessor: address(linkProcessor)
        });
        assertTrue(acs.hasRole(LINK_MANAGER_ROLE, linkManager));
        vm.prank(linkManager);
        linkingModule.setProtocolLink(protocolLink, params);

        LinkingModule.LinkConfig memory config = linkingModule.protocolLinks(protocolLink);
        assertEq(config.sourceIPAssetTypeMask, 1 << (uint256(IPAsset.STORY) & 0xff));
        assertEq(config.destIPAssetTypeMask, 1 << (uint256(IPAsset.CHARACTER) & 0xff) | 1 << (uint256(IPAsset.ART) & 0xff) | (uint256(EXTERNAL_ASSET) << 248));
        assertTrue(config.linkOnlySameFranchise);
        // TODO: test for event

    }

    function test_revert_IfSettingProtocolLevelLinkUnauthorized() public {
        IPAsset[] memory sourceIPAssets = new IPAsset[](1);
        sourceIPAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIPAssets = new IPAsset[](2);
        destIPAssets[0] = IPAsset.CHARACTER;
        destIPAssets[1] = IPAsset.ART;

        LinkingModule.SetLinkParams memory params = ILinkingModule.SetLinkParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            linkOnlySameFranchise: true,
            linkProcessor: address(linkProcessor)
        });
        vm.expectRevert();
        vm.prank(franchiseOwner);
        linkingModule.setProtocolLink(protocolLink, params);
    }

    function test_revert_IfMasksNotConfigured() public {
        IPAsset[] memory sourceIPAssets = new IPAsset[](1);
        sourceIPAssets[0] = IPAsset.UNDEFINED;
        IPAsset[] memory destIPAssets = new IPAsset[](2);

        LinkingModule.SetLinkParams memory params = ILinkingModule.SetLinkParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            linkOnlySameFranchise: true,
            linkProcessor: address(linkProcessor)
        });
        vm.startPrank(linkManager);
        vm.expectRevert();
        linkingModule.setProtocolLink(protocolLink, params);
    }

}

contract LinkingModuleUnsetLinksTest is Test, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    FranchiseRegistry public register;
    LinkingModule public linkingModule;
    AccessControlSingleton acs;
    PermissionlessLinkProcessor public linkProcessor;

    address admin = address(123);
    address linkManager = address(234);
    address franchiseOwner = address(456);

    bytes32 protocolLink = keccak256("PROTOCOL_LINK");

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
        linkingModule = LinkingModule(
            _deployUUPSProxy(
                address(new LinkingModule(address(register))),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(acs)
                )
            )
        );
        linkProcessor = new PermissionlessLinkProcessor(address(linkingModule));
        IPAsset[] memory sourceIPAssets = new IPAsset[](1);
        sourceIPAssets[0] = IPAsset.STORY;
        IPAsset[] memory destIPAssets = new IPAsset[](1);
        destIPAssets[0] = IPAsset.CHARACTER;
        LinkingModule.SetLinkParams memory params = ILinkingModule.SetLinkParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: true,
            linkOnlySameFranchise: true,
            linkProcessor: address(linkProcessor)
        });
        vm.prank(linkManager);
        linkingModule.setProtocolLink(protocolLink, params);
        
    }

    function test_unsetProtocolLink() public {
        vm.prank(linkManager);
        linkingModule.unsetProtocolLink(protocolLink);

        LinkingModule.LinkConfig memory config = linkingModule.protocolLinks(protocolLink);
        assertEq(config.sourceIPAssetTypeMask, 0);
        assertEq(config.destIPAssetTypeMask, 0);
        assertFalse(config.linkOnlySameFranchise);
        // TODO: test for event
    }

    function test_revert_unsetProtocolLinkNotAuthorized() public {
        vm.expectRevert();
        linkingModule.unsetProtocolLink(protocolLink);
    }

    function test_revert_unsetProtocolLinkNonExistingLink() public {
        vm.prank(linkManager);
        vm.expectRevert(ILinkingModule.NonExistingLink.selector);
        linkingModule.unsetProtocolLink(keccak256("UNDEFINED_LINK"));
    }

}
