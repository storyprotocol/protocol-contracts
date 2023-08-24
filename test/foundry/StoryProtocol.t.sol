// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/BaseTest.sol';
import "contracts/libraries/DataTypes.sol";

contract StoryProtocolTest is BaseTest {

    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
    }

    function test_setUp() public {
        assertEq(storyProtocol.version(), "0.1.0");
    }

    function test_storyProtocol_registerFranchise() public {
        DataTypes.FranchiseCreationParams memory params = DataTypes.FranchiseCreationParams("name2", "symbol2", "description2", "tokenURI2", franchiseOwner);
        vm.startPrank(franchiseOwner);
        (uint256 id, address ipAsset) = storyProtocol.registerFranchise(params);
        assertEq(id, 2);
        assertFalse(ipAsset == address(0));
        assertEq(ipAsset, franchiseRegistry.ipAssetRegistryForId(id));
        assertEq(franchiseRegistry.ownerOf(id), franchiseOwner);
        assertEq(franchiseRegistry.tokenURI(id), "tokenURI2");
        vm.stopPrank();
    }

}
