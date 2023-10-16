// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/BaseTest.sol';

contract IPAssetControllerTest is BaseTest {

    event IPAssetGroupRegistered(
        address owner,
        uint256 id,
        address ipAssetRegistryForId,
        string name,
        string symbol,
        string tokenURI
    );
    
    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
    }

    // function test_setUp() public {
    //     assertEq(ipAssetController.version(), "0.1.0");
    //     assertEq(ipAssetController.name(), "Story Protocol");
    //     assertEq(ipAssetController.symbol(), "SP");
    // }

    // function test_registerIPAssetGroup() public {
    //     IPAssetController.IPAssetGroupCreationParams memory params = IPAssetController.IPAssetGroupCreationParams("name2", "symbol2", "description2", "tokenURI2");
    //     vm.startPrank(franchiseOwner);
    //     vm.expectCall(address(factory),
    //         abi.encodeCall(
    //             factory.createIPAssetGroupIpAssets,
    //             (
    //                 2,
    //                 "name2",
    //                 "symbol2",
    //                 "description2"
    //             )
    //         )
    //     );
    //     vm.expectEmit(false, true, false, false);
    //     emit IPAssetGroupRegistered(address(0x123), 2, address(0x234), "name2", "symbol2", "tokenURI2");
    //     (uint256 id, address ipAsset) = ipAssetController.registerIPAssetGroup(params);
    //     assertEq(id, 2);
    //     assertFalse(ipAsset == address(0));
    //     assertEq(ipAsset, ipAssetController.ipAssetRegistryForId(id));
    //     assertEq(ipAssetController.ownerOf(id), franchiseOwner);
    //     assertEq(ipAssetController.tokenURI(id), "tokenURI2");
    //     vm.stopPrank();
    // }

    // function test_isIpAssetRegistry() public {
    //     vm.prank(franchiseOwner);
    //     IPAssetController.IPAssetGroupCreationParams memory params = IPAssetController.IPAssetGroupCreationParams("name", "symbol2", "description2", "tokenURI2");   
    //     (uint256 id, address ipAsset) = ipAssetController.registerIPAssetGroup(params);
    //     assertTrue(ipAssetController.isIpAssetRegistry(ipAsset));
    // }

    // function test_isNotIpAssetRegistry() public {
    //     assertFalse(ipAssetController.isIpAssetRegistry(address(ipAssetController)));
    // }

    // function test_revert_tokenURI_not_registered() public {
    //     vm.expectRevert("ERC721: invalid token ID");
    //     ipAssetController.tokenURI(420);
    // }

    // function test_CreateIPAssetGroupBlocks() public {
    //     vm.expectEmit(false, true, true, true);
    //     emit IPAssetGroupCreated(address(0x123), "name", "symbol");
    //     // TODO: figure why this is not matching correctly, the event is emitted according to traces
    //     // vm.expectEmit();
    //     // emit BeaconUpgraded(address(0x123));
    //     address collection = factory.createIPAssetGroupIpAssets(1, "name", "symbol", "description");
    //     assertTrue(collection != address(0));
    //     assertEq(IPAssetGroup(collection).name(), "name");
    //     assertEq(IPAssetGroup(collection).symbol(), "symbol");
    // }

    // function test_UpgradeCollections() public {
    //     IPAssetGroupv2 newImplementation = new IPAssetGroupv2(_mockEventEmitter, mockLicenseModule, mockIPAssetController, mockCollectModule);
    //     //vm.expectEmit(true, true, true, true);
    //     //emit CollectionsUpgraded(address(newImplementation), "2.0.0");
    //     factory.upgradeIPAssetGroups(address(newImplementation));
    //     UpgradeableBeacon beacon = factory.BEACON();
    //     assertEq(IPAssetGroup(beacon.implementation()).version(), "2.0.0");
    // }

    // function test_revertIfNotOwnerUpgrades() public {
    //     IPAssetGroupv2 newImplementation = new IPAssetGroupv2(_mockEventEmitter, mockLicenseModule, mockIPAssetController, mockCollectModule);
    //     vm.prank(notOwner);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     factory.upgradeIPAssetGroups(address(newImplementation));
    // }
}
