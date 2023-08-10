// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/BaseTest.sol';

contract FranchiseRegistryTest is BaseTest {

    event FranchiseRegistered(
        address owner,
        uint256 id,
        address ipAssetRegistryForId,
        string name,
        string symbol
    );
    
    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
    }

    function test_setUp() public {
        assertEq(franchiseRegistry.version(), "0.1.0");
        assertEq(franchiseRegistry.name(), "Story Protocol");
        assertEq(franchiseRegistry.symbol(), "SP");
    }

    function test_registerFranchise() public {
        vm.startPrank(franchiseOwner);
        vm.expectCall(address(factory),
            abi.encodeCall(
                factory.createFranchiseIPAssets,
                (
                    2,
                    "name2",
                    "symbol2",
                    "description2"
                )
            )
        );
        vm.expectEmit(false, true, false, false);
        emit FranchiseRegistered(address(0x123), 2, address(0x234), "name2", "symbol2");
        (uint256 id, address ipAsset) = franchiseRegistry.registerFranchise("name2", "symbol2", "description2");
        assertEq(id, 2);
        assertFalse(ipAsset == address(0));
        assertEq(ipAsset, franchiseRegistry.ipAssetRegistryForId(id));
        assertEq(franchiseRegistry.ownerOf(id), franchiseOwner);
        vm.stopPrank();
    }

    function test_isIpAssetRegistry() public {
        vm.prank(franchiseOwner);   
        (uint256 id, address ipAsset) = franchiseRegistry.registerFranchise("name", "symbol", "description");
        assertTrue(franchiseRegistry.isIpAssetRegistry(ipAsset));
    }

    function test_isNotIpAssetRegistry() public {
        assertFalse(franchiseRegistry.isIpAssetRegistry(address(franchiseRegistry)));
    }
}
