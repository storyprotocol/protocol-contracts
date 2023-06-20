// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/ProxyHelper.sol';
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/story-blocks/StoryBlocksRegistryFactory.sol";

contract FranchiseRegistryTest is Test, ProxyHelper {
    StoryBlocksRegistryFactory public factory;
    FranchiseRegistry public register;

    address admin;

    function setUp() public {
        factory = new StoryBlocksRegistryFactory();
        address accessControl = address(new AccessControlSingleton());
        
        FranchiseRegistry impl = new FranchiseRegistry(address(factory));
        register = FranchiseRegistry(
            _deployUUPSProxy(
                address(impl),
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), accessControl
                )
            )
        );
    }

   
}
