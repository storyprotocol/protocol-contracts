// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/ProxyHelper.sol';
import "../../contracts/SPRegistry.sol";
import "../../contracts/access-control/AccessControlSingleton.sol";
import "../../contracts/franchises/SPFranchiseNFTFactory.sol";

contract SPRegistryTest is Test, ProxyHelper {

    event FranchiseRegistered(address indexed to, uint256 indexed franchiseId, address indexed nftAddress);
    event FranchiseCreated(address indexed collection, string name, string indexed symbol);

    SPFranchiseNFTFactory public factory;
    SPRegistry public register;

    address admin;
    address franchiseAdmin = address(0x234);

    function setUp() public {
        factory = new SPFranchiseNFTFactory();
        address accessControl = address(new AccessControlSingleton());
        
        SPRegistry impl = new SPRegistry(address(factory));
        register = SPRegistry(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), accessControl
                )
            )
        );
    }

    function test_registerFranchise() public {
        vm.expectEmit(false, true, true, true);
        emit FranchiseCreated(address(0x123), "name", "symbol");
        vm.expectEmit(true, true, false, true);
        emit FranchiseRegistered(franchiseAdmin, 1, address(0x123));
        address franchise = register.registerFranchise(franchiseAdmin, "name", "symbol", "description");
        assertEq(register.franchiseContract(1), franchise, "franchise address");
        assertEq(register.ownerOf(1), franchiseAdmin, "owner");
    }

   
}
