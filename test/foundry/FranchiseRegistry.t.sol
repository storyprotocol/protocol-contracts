// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/ProxyHelper.sol';
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/story-blocks/StoryBlocksRegistryFactory.sol";

contract FranchiseRegistryTest is Test, ProxyHelper {

    event FranchiseRegistered(
        address owner,
        uint256 id,
        address storyBlocksContract
    );
    
    StoryBlocksRegistryFactory public factory;
    FranchiseRegistry public register;

    address admin = address(123);
    address franchiseOwner = address(456);

    AccessControlSingleton acs;

    function setUp() public {
        factory = new StoryBlocksRegistryFactory();
        vm.prank(admin);
        acs = new AccessControlSingleton();
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
                factory.createFranchiseBlocks,
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
        (uint256 id, address storyBlocks) = register.registerFranchise("name", "symbol", "description");
        assertEq(id, 1);
        assertFalse(storyBlocks == address(0));
        assertEq(storyBlocks, register.storyBlocksContract(id));
        assertEq(register.ownerOf(id), franchiseOwner);
    }
}
