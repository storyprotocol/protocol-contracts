// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";
import { IPOrg } from "contracts/ip-org/IPOrg.sol";
import { IPOrgFactory } from "contracts/ip-org/IPOrgFactory.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { MockCollectNFT } from "./mocks/MockCollectNFT.sol";
import { MockCollectModule } from "./mocks/MockCollectModule.sol";
import { MockLicensingModule } from "./mocks/MockLicensingModule.sol";
import { MockIPOrgFactory } from "./mocks/MockIPOrgFactory.sol";
import "forge-std/Test.sol";

contract IPOrgTest is Test {
    using stdStorage for StdStorage;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    error IdOverBounds();
    error InvalidBlockType();

    IPAssetRegistry public registry;
    IPOrgFactory public ipOrgFactory;
    IPOrg public ipOrg;
    address owner = address(this);
    address mintee = address(1);
    address mintee2 = address(2);

    uint256 internal ipOrgOwnerPk = 0xa11ce;
    address payable internal ipOrgOwner = payable(vm.addr(ipOrgOwnerPk));

    function setUp() public {
        registry = new IPAssetRegistry();
        ipOrgFactory = new IPOrgFactory();

        IPAsset.RegisterIPOrgParams memory ipOrgParams = IPAsset.RegisterIPOrgParams(
            address(registry),
            "name",
            "symbol",
            "description",
            "uri"
        );
        vm.prank(ipOrgOwner);
        address ipOrgAddr;
        ipOrgAddr = ipOrgFactory.registerIPOrg(ipOrgParams);
        ipOrg = IPOrg(ipOrgAddr);
    }

    function test_setUp() public {
        assertEq(ipOrg.name(), "name");
        assertEq(ipOrg.symbol(), "symbol");
        assertEq(ipOrg.version(), "0.1.0");
    }

}
