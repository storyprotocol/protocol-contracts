// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";
import { IPOrg } from "contracts/ip-org/IPOrg.sol";
import { IPOrgFactory } from "contracts/ip-org/IPOrgFactory.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { AccessControlSingleton } from "contracts/access-control/AccessControlSingleton.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { AccessControlHelper } from "./utils/AccessControlHelper.sol";
import { MockCollectNFT } from "./mocks/MockCollectNFT.sol";
import { MockCollectModule } from "./mocks/MockCollectModule.sol";
import { MockLicensingModule } from "./mocks/MockLicensingModule.sol";
import { MockIPOrgFactory } from "./mocks/MockIPOrgFactory.sol";
import 'test/foundry/utils/ProxyHelper.sol';
import "forge-std/Test.sol";

contract IPOrgTest is Test, ProxyHelper, AccessControlHelper {
    using stdStorage for StdStorage;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    IPAssetRegistry public registry;
    IPOrgFactory public ipOrgFactory;
    IPOrg public ipOrg;

    uint256 internal ipOrgOwnerPk = 0xa11ce;
    address payable internal ipOrgOwner = payable(vm.addr(ipOrgOwnerPk));

    function setUp() public {
        _setupAccessControl();
        _grantRole(vm, AccessControl.IPORG_CREATOR_ROLE, ipOrgOwner);
        registry = new IPAssetRegistry();

        address implementation = address(new IPOrgFactory());
        ipOrgFactory = IPOrgFactory(
            _deployUUPSProxy(
                implementation,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
                )
            )
        );
    }

    function test_ipOrgFactory_registerIpOrg() public {
        IPOrgParams.RegisterIPOrgParams memory ipOrgParams = IPOrgParams.RegisterIPOrgParams(
            address(registry),
            "name",
            "symbol",
            "description",
            "uri"
        );
        vm.prank(ipOrgOwner);
        ipOrg = IPOrg(ipOrgFactory.registerIpOrg(ipOrgParams));
    }

}
