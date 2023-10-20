// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/BaseTest.sol';

contract IPAssetOrgFactoryTest is BaseTest {

    event IPAssetOrgRegistered(
        address owner,
        uint256 id,
        address ipAssetOrgForId,
        string name,
        string symbol,
        string tokenURI
    );
    
    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
    }

    // function test_setUp() public {
    //     assertEq(franchise.version(), "0.1.0");
    //     assertEq(franchise.name(), "Story Protocol");
    //     assertEq(franchise.symbol(), "SP");
    // }

    // function test_registerIPAssetOrg() public {
    //     IPAssetOrgFactory.IPAssetOrgCreationParams memory params = IPAssetOrgFactory.IPAssetOrgCreationParams("name2", "symbol2", "description2", "tokenURI2");
    //     vm.startPrank(franchiseOwner);
    //     vm.expectCall(address(factory),
    //         abi.encodeCall(
    //             factory.createIPAssetOrgIpAssets,
    //             (
    //                 2,
    //                 "name2",
    //                 "symbol2",
    //                 "description2"
    //             )
    //         )
    //     );
    //     vm.expectEmit(false, true, false, false);
    //     emit IPAssetOrgRegistered(address(0x123), 2, address(0x234), "name2", "symbol2", "tokenURI2");
    //     (uint256 id, address ipAsset) = franchise.registerIPAssetOrg(params);
    //     assertEq(id, 2);
    //     assertFalse(ipAsset == address(0));
    //     assertEq(ipAsset, franchise.ipAssetOrgForId(id));
    //     assertEq(franchise.ownerOf(id), franchiseOwner);
    //     assertEq(franchise.tokenURI(id), "tokenURI2");
    //     vm.stopPrank();
    // }

    // function test_isIpAssetOrg() public {
    //     vm.prank(franchiseOwner);
    //     IPAssetOrgFactory.IPAssetOrgCreationParams memory params = IPAssetOrgFactory.IPAssetOrgCreationParams("name", "symbol2", "description2", "tokenURI2");   
    //     (uint256 id, address ipAsset) = franchise.registerIPAssetOrg(params);
    //     assertTrue(franchise.isIpAssetOrg(ipAsset));
    // }

    // function test_isNotIPAssetOrg() public {
    //     assertFalse(franchise.isIpAssetOrg(address(franchise)));
    // }

    // function test_revert_tokenURI_not_registered() public {
    //     vm.expectRevert("ERC721: invalid token ID");
    //     franchise.tokenURI(420);
    // }

    // function test_CreateIPAssetOrgBlocks() public {
    //     vm.expectEmit(false, true, true, true);
    //     emit IPAssetOrgCreated(address(0x123), "name", "symbol");
    //     // TODO: figure why this is not matching correctly, the event is emitted according to traces
    //     // vm.expectEmit();
    //     // emit BeaconUpgraded(address(0x123));
    //     address collection = factory.createIPAssetOrgIpAssets(1, "name", "symbol", "description");
    //     assertTrue(collection != address(0));
    //     assertEq(IPAssetOrg(collection).name(), "name");
    //     assertEq(IPAssetOrg(collection).symbol(), "symbol");
    // }

    // function test_UpgradeCollections() public {
    //     IPAssetOrgv2 newImplementation = new IPAssetOrgv2(_mockEventEmitter, mockLicenseModule, mockIPAssetOrgFactory, mockCollectModule);
    //     //vm.expectEmit(true, true, true, true);
    //     //emit CollectionsUpgraded(address(newImplementation), "2.0.0");
    //     factory.upgradeIPAssetOrgs(address(newImplementation));
    //     UpgradeableBeacon beacon = factory.BEACON();
    //     assertEq(IPAssetOrg(beacon.implementation()).version(), "2.0.0");
    // }

    // function test_revertIfNotOwnerUpgrades() public {
    //     IPAssetOrgv2 newImplementation = new IPAssetOrgv2(_mockEventEmitter, mockLicenseModule, mockIPAssetOrgFactory, mockCollectModule);
    //     vm.prank(notOwner);
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     factory.upgradeIPAssetOrgs(address(newImplementation));
    // }
}
