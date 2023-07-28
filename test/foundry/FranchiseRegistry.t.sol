// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/ProxyHelper.sol';
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/ip-assets/IPAssetRegistryFactory.sol";
import "contracts/ip-assets/events/CommonIPAssetEventEmitter.sol";

contract FranchiseRegistryTest is Test, ProxyHelper {

    event FranchiseRegistered(
        address owner,
        uint256 id,
        address ipAssetRegistryForId
    );
    
    IPAssetRegistryFactory public factory;
    FranchiseRegistry public register;

    address admin = address(123);
    address franchiseOwner = address(456);

    AccessControlSingleton acs;

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

        address eventEmitter = address(new CommonIPAssetEventEmitter(address(register)));
        address ipAssetRegistry = address(new IPAssetRegistry(eventEmitter));

        factory.upgradeFranchises(ipAssetRegistry);
    }

    function test_setUp() public {
        assertEq(register.version(), "0.1.0");
        assertEq(register.name(), "Story Protocol");
        assertEq(register.symbol(), "SP");
    }

    function test_registerFranchise() public {
        vm.startPrank(franchiseOwner);
        vm.expectCall(address(factory),
            abi.encodeCall(
                factory.createFranchiseIPAssets,
                (
                    1,
                    "name",
                    "symbol",
                    "description"
                )
            )
        );
        vm.expectEmit(false, true, false, false);
        emit FranchiseRegistered(address(0x123), 1, address(0x234));
        (uint256 id, address ipAsset) = register.registerFranchise("name", "symbol", "description");
        assertEq(id, 1);
        assertFalse(ipAsset == address(0));
        assertEq(ipAsset, register.ipAssetRegistryForId(id));
        assertEq(register.ownerOf(id), franchiseOwner);
        vm.stopPrank();
    }

    function test_isIpAssetRegistry() public {
        vm.prank(franchiseOwner);   
        (uint256 id, address ipAsset) = register.registerFranchise("name", "symbol", "description");
        assertTrue(register.isIpAssetRegistry(ipAsset));
    }

    function test_isNotIpAssetRegistry() public {
        assertFalse(register.isIpAssetRegistry(address(register)));
    }
}
