// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import { Errors } from "contracts/lib/Errors.sol";
import { IPOrg } from "contracts/ip-org/IPOrg.sol";
import { IPOrgController } from "contracts/ip-org/IPOrgController.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { IPOrgParams } from "contracts/lib/IPOrgParams.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { LicenseRegistry } from "contracts/modules/licensing/LicenseRegistry.sol";
import { AccessControlSingleton } from "contracts/access-control/AccessControlSingleton.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { AccessControlHelper } from "./utils/AccessControlHelper.sol";
import { MockCollectNFT } from "./mocks/MockCollectNFT.sol";
import { MockCollectModule } from "./mocks/MockCollectModule.sol";
import { MockIPOrgController } from "./mocks/MockIPOrgController.sol";
import { BaseModule } from "contracts/modules/base/BaseModule.sol";
import { RegistrationModule } from "contracts/modules/registration/RegistrationModule.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import 'test/foundry/utils/ProxyHelper.sol';
import "forge-std/Test.sol";

contract IPOrgTest is Test, ProxyHelper, AccessControlHelper {
    using stdStorage for StdStorage;

    event CollectionCreated(address indexed collection, string name, string indexed symbol);
    event CollectionsUpgraded(address indexed newImplementation, string version);
    event BeaconUpgraded(address indexed beacon);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    RegistrationModule public registrationModule;
    LicenseRegistry public licenseRegistry;
    IPAssetRegistry public registry;
    IPOrgController public ipOrgController;
    ModuleRegistry public moduleRegistry;
    IPOrg public ipOrg;

    uint256 internal ipOrgOwnerPk = 0xa11ce;
    address payable internal ipOrgOwner = payable(vm.addr(ipOrgOwnerPk));

    function setUp() public {
        _setupAccessControl();
        _grantRole(vm, AccessControl.IPORG_CREATOR_ROLE, ipOrgOwner);

        moduleRegistry = new ModuleRegistry(address(accessControl));
        registry = new IPAssetRegistry(address(moduleRegistry));
        address ipOrgControllerImpl = address(new IPOrgController(address(moduleRegistry)));
        ipOrgController = IPOrgController(
            _deployUUPSProxy(
                ipOrgControllerImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))),
                    address(accessControl)
                )
            )
        );
        _grantRole(vm, AccessControl.MODULE_EXECUTOR_ROLE, address(address(ipOrgController)));

        licenseRegistry = new LicenseRegistry(address(registry), address(moduleRegistry));
        registrationModule = new RegistrationModule(
            BaseModule.ModuleConstruction({
                ipaRegistry: registry,
                moduleRegistry: moduleRegistry,
                licenseRegistry: licenseRegistry,
                ipOrgController: ipOrgController
            }),
            address(accessControl)
        );
        _grantRole(vm, AccessControl.MODULE_REGISTRAR_ROLE, address(this));
        moduleRegistry.registerProtocolModule(ModuleRegistryKeys.REGISTRATION_MODULE, registrationModule);

    }

    function test_ipOrgController_registerIpOrg() public {
        vm.prank(ipOrgOwner);
        string[] memory ipAssetTypes = new string[](0);
        ipOrg = IPOrg(ipOrgController.registerIpOrg(msg.sender, "name", "symbol", ipAssetTypes));
    }

}
