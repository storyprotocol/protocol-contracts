// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/ProxyHelper.sol';
import "../../contracts/SPRegistry.sol";
import "../../contracts/access-control/AccessControlSingleton.sol";
import "../../contracts/franchises/SPFranchiseNFTFactory.sol";

contract SPRegistryTest is Test, ProxyHelper {
    SPFranchiseNFTFactory public factory;
    SPRegistry public register;

    address admin;

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

   
}
