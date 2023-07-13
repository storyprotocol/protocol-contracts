// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import '../utils/ProxyHelper.sol';
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/access-control/ProtocolRoles.sol";
import "contracts/ip-assets/IPAssetRegistryFactory.sol";
import "contracts/modules/linking/LinkingModule.sol";

contract LinkingModuleFranchiseTest is Test, ProxyHelper {

    IPAssetRegistryFactory public factory;
    IPAssetRegistry public ipAssetRegistry;
    FranchiseRegistry public register;
    LinkingModule public linkingModule;

    address admin = address(123);
    address linkManager = address(234);
    address franchiseOwner = address(456);

    AccessControlSingleton acs;

    function setUp() public {
        factory = new IPAssetRegistryFactory();
        vm.prank(admin);
        acs = new AccessControlSingleton();
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
        linkingModule = new LinkingModule(address(register));
        
    }

    function test_setProtocolLevelLink() public {
        vm.prank(linkManager);
        
    }

    function test_revert_IfSettingProtocolLevelLinkUnauthorized() public {
        vm.expectRevert();
    }

    function test_revert_IfMasksNotConfigured() public {
        vm.expectRevert();
    }

    function test_revert_IfWrongPermissionChecker() public {
        vm.expectRevert();
    }

    function test_linkMasks() public {
        
    }
}
