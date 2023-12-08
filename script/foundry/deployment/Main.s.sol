// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "test/foundry/utils/ProxyHelper.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "contracts/ip-org/IPOrg.sol";
import "contracts/ip-org/IPOrgController.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import "contracts/modules/ModuleRegistry.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/modules/registration/RegistrationModule.sol";
import "contracts/StoryProtocol.sol";
import "contracts/modules/base/BaseModule.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/lib/modules/ModuleRegistryKeys.sol";
import "contracts/modules/licensing/LicensingModule.sol";
import "contracts/hooks/TokenGatedHook.sol";
import "contracts/hooks/PolygonTokenHook.sol";
import "contracts/modules/base/HookRegistry.sol";
import "contracts/interfaces/hooks/base/IHook.sol";
import { TokenGated } from "contracts/lib/hooks/TokenGated.sol";
import "test/foundry/mocks/MockERC721.sol";
import "contracts/modules/licensing/LicenseRegistry.sol";
import "contracts/modules/licensing/LicensingFrameworkRepo.sol";
import "contracts/modules/licensing/LicensingModule.sol";
import "contracts/lib/modules/Licensing.sol";
import "contracts/lib/modules/SPUMLParams.sol";
import { PolygonToken } from "contracts/lib/hooks/PolygonToken.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import "script/foundry/utils/HooksFactory.sol";
import { ModuleKey, LICENSING_MODULE_KEY, REGISTRATION_MODULE_KEY, RELATIONSHIP_MODULE_KEY } from "contracts/lib/modules/Module.sol";


contract Main is Script, BroadcastManager, JsonDeploymentHandler, ProxyHelper {
    using StringUtil for uint256;
    using stdJson for string;

    address accessControl;
    address ipOrgController;
    address moduleRegistry;
    address ipAssetRegistry;
    address spg;
    address licenseRegistry;
    address registrationModule;
    address relationshipModule;
    address licensingModule;
    address tokenGatedHook;
    address polygonTokenHook;
    address mockNFT;
    address licensingFrameworkRepo;
    address hooksFactory;

    constructor() JsonDeploymentHandler("main") {}

    /// @dev To use, run the following command (e.g. for Sepolia):
    /// forge script script/foundry/deployment/Main.s.sol:Main --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv

    function run() public {
        _beginBroadcast();
        string memory contractKey;
        address newAddress;

        /// ACCESS CONTROL SINGLETON
        contractKey = "AccessControlSingleton-Impl";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new AccessControlSingleton());
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        contractKey = "AccessControlSingleton-Proxy";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = _deployUUPSProxy(
            newAddress,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("initialize(address)"))),
                admin
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        accessControl = newAddress;

        /// LICENSING_FRAMEWORK_REPO
        contractKey = "LicensingFrameworkRepo";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new LicensingFrameworkRepo(accessControl));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        licensingFrameworkRepo = newAddress;

        /// MODULE_REGISTRY
        contractKey = "ModuleRegistry";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new ModuleRegistry(accessControl));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        moduleRegistry = newAddress;

        /// IP_ASSET_REGISTRY
        contractKey = "IPAssetRegistry";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new IPAssetRegistry(moduleRegistry));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        ipAssetRegistry = newAddress;

        /// LICENSE_REGISTRY
        contractKey = "LicenseRegistry";
        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(
            new LicenseRegistry(
                ipAssetRegistry,
                moduleRegistry,
                licensingFrameworkRepo
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        licenseRegistry = newAddress;

        /// IP_ORG_FACTORY REGISTRY
        contractKey = "IPOrgController-Impl";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new IPOrgController(moduleRegistry));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        contractKey = "IPOrgController-Proxy";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = _deployUUPSProxy(
            newAddress,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("initialize(address)"))),
                accessControl
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        ipOrgController = newAddress;

        /// SPG
        contractKey = "StoryProtocol";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(
            new StoryProtocol(
                IIPOrgController(ipOrgController),
                ModuleRegistry(moduleRegistry)
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        spg = newAddress;

        /// REGISTRATION_MODULE
        contractKey = "RegistrationModule";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(
            new RegistrationModule(
                BaseModule.ModuleConstruction({
                    ipaRegistry: IPAssetRegistry(ipAssetRegistry),
                    moduleRegistry: ModuleRegistry(moduleRegistry),
                    licenseRegistry: LicenseRegistry(licenseRegistry),
                    ipOrgController: IPOrgController(ipOrgController)
                }),
                accessControl
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        registrationModule = newAddress;

        /// RELATIONSHIP_MODULE
        contractKey = "RelationshipModule";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(
            new RelationshipModule(
                BaseModule.ModuleConstruction({
                    ipaRegistry: IPAssetRegistry(ipAssetRegistry),
                    moduleRegistry: ModuleRegistry(moduleRegistry),
                    licenseRegistry: LicenseRegistry(licenseRegistry),
                    ipOrgController: IPOrgController(ipOrgController)
                }),
                accessControl
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        relationshipModule = newAddress;

        /// LICENSE_MODULE
        contractKey = "LicensingModule";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(
            new LicensingModule(
                BaseModule.ModuleConstruction({
                    ipaRegistry: IPAssetRegistry(ipAssetRegistry),
                    moduleRegistry: ModuleRegistry(moduleRegistry),
                    licenseRegistry: LicenseRegistry(licenseRegistry),
                    ipOrgController: IPOrgController(ipOrgController)
                }),
                licensingFrameworkRepo,
                admin
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        licensingModule = newAddress;

        /// HOOKS_FACTORY
        contractKey = "HooksFactory";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new HooksFactory());
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        hooksFactory = newAddress;

        /// TOKEN_GATED_HOOK
        contractKey = "TokenGatedHook";

        console.log(string.concat("Deploying ", contractKey, "..."));
        bytes memory tokenGatedHookCode = abi.encodePacked(
            type(TokenGatedHook).creationCode, abi.encode(address(accessControl)));
        newAddress = HooksFactory(hooksFactory).deploy(tokenGatedHookCode, Hook.SYNC_FLAG, block.timestamp);
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        tokenGatedHook = newAddress;

        /// POLYGON_TOKEN_HOOK
        contractKey = "PolygonTokenHook";

        console.log(string.concat("Deploying ", contractKey, "..."));
        bytes memory polygonTokenHookCode = abi.encodePacked(
            type(PolygonTokenHook).creationCode,
            abi.encode(
                address(accessControl),
                vm.envAddress("POLYGON_TOKEN_ORACLE_CLIENT"),
                vm.envAddress("POLYGON_TOKEN_ORACLE_COORDINATOR")
            ));
        newAddress = HooksFactory(hooksFactory).deploy(polygonTokenHookCode, Hook.ASYNC_FLAG, block.timestamp);
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        polygonTokenHook = newAddress;

        /// MOCK_ERC_721
        contractKey = "MockERC721";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new MockERC721());
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        mockNFT = newAddress;

        /////////////////////////////////////////////////////////////////////////////////////////////////////
        //                                      CONFIGURATION                                              //
        /////////////////////////////////////////////////////////////////////////////////////////////////////

        /// GRANT ROLEs
        AccessControlSingleton accessControlSingleton = AccessControlSingleton(
            accessControl
        );
        accessControlSingleton.grantRole(AccessControl.UPGRADER_ROLE, admin);
        accessControlSingleton.grantRole(
            AccessControl.RELATIONSHIP_MANAGER_ROLE,
            admin
        );
        accessControlSingleton.grantRole(
            AccessControl.LICENSING_MANAGER_ROLE,
            admin
        );
        accessControlSingleton.grantRole(
            AccessControl.LICENSING_MANAGER,
            admin
        );
        accessControlSingleton.grantRole(
            AccessControl.IPORG_CREATOR_ROLE,
            admin
        );
        accessControlSingleton.grantRole(
            AccessControl.MODULE_REGISTRAR_ROLE,
            admin
        );
        accessControlSingleton.grantRole(
            AccessControl.MODULE_EXECUTOR_ROLE,
            spg
        );
        accessControlSingleton.grantRole(
            AccessControl.MODULE_EXECUTOR_ROLE,
            ipOrgController
        );
        accessControlSingleton.grantRole(
            AccessControl.HOOK_CALLER_ROLE,
            moduleRegistry
        );
        accessControlSingleton.grantRole(
            AccessControl.HOOK_CALLER_ROLE,
            registrationModule
        );
        accessControlSingleton.grantRole(
            AccessControl.HOOK_CALLER_ROLE,
            relationshipModule
        );
        accessControlSingleton.grantRole(
            AccessControl.HOOK_CALLER_ROLE,
            licensingModule
        );

        // REGISTER MODULES
        ModuleRegistry(moduleRegistry).registerProtocolModule(
            REGISTRATION_MODULE_KEY,
            BaseModule(registrationModule)
        );
        ModuleRegistry(moduleRegistry).registerProtocolModule(
            RELATIONSHIP_MODULE_KEY,
            BaseModule(relationshipModule)
        );
        ModuleRegistry(moduleRegistry).registerProtocolModule(
            LICENSING_MODULE_KEY,
            BaseModule(licensingModule)
        );
        string[] memory ipAssetTypes = new string[](2);
        ipAssetTypes[0] = "STORY";
        ipAssetTypes[1] = "CHARACTER";
        address ipOrg = StoryProtocol(spg).registerIpOrg(
            admin,
            "Sample IP Org",
            "SIPO",
            ipAssetTypes
        );

        // REGISTER TOKEN_GATED_HOOK and POLYGON_TOKEN_HOOK
        ModuleRegistry(moduleRegistry).registerProtocolHook("TOKEN_GATED_HOOK", IHook(tokenGatedHook));
        ModuleRegistry(moduleRegistry).registerProtocolHook("POLYGON_TOKEN_HOOK", IHook(polygonTokenHook));
        address[] memory hooks = new address[](2);
        hooks[0] = tokenGatedHook;
        hooks[1] = polygonTokenHook;

        TokenGated.Config memory tokenGatedConfig = TokenGated.Config({
            tokenAddress: mockNFT
        });
        PolygonToken.Config memory polygonTokenConfig = PolygonToken.Config({
            tokenAddress: mockNFT,
            balanceThreshold: 1
        });
        bytes[] memory hooksConfig = new bytes[](2);
        hooksConfig[0] = abi.encode(tokenGatedConfig);
        hooksConfig[1] = abi.encode(polygonTokenConfig);
        RegistrationModule(registrationModule).registerHooks(
            HookRegistry.HookType.PreAction,
            IIPOrg(ipOrg),
            hooks,
            hooksConfig,
            abi.encode(Registration.REGISTER_IP_ASSET)
        );

        // CONFIG LICENSING MODULE
        Licensing.ParamDefinition[] memory paramDefs = SPUMLParams.getParamDefs();
        Licensing.SetFramework memory framework = Licensing.SetFramework({
            id: SPUMLParams.FRAMEWORK_ID,
            textUrl: vm.envString("SPUML_URL"),
            paramDefs: paramDefs
        });
        LicensingFrameworkRepo(licensingFrameworkRepo).addFramework(framework);

        _writeDeployment();
        _endBroadcast();
    }
}
