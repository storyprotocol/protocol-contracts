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
import "test/foundry/mocks/MockCollectNFT.sol";
import "test/foundry/mocks/MockCollectModule.sol";
import "contracts/modules/royalties/RoyaltyDistributor.sol";
import "contracts/modules/royalties/policies/MutableRoyaltyProportionPolicy.sol";
import "contracts/modules/royalties/RoyaltyNFT.sol";
import "contracts/ip-accounts/IPAccountImpl.sol";
import "contracts/ip-accounts/IPAccountRegistry.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import "contracts/modules/ModuleRegistry.sol";
import "contracts/IPAssetRegistry.sol";
import "contracts/modules/registration/RegistrationModule.sol";
import "contracts/StoryProtocol.sol";
import "contracts/modules/base/BaseModule.sol";
import "contracts/modules/licensing/LicenseRegistry.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/lib/modules/ModuleRegistryKeys.sol";
import "contracts/modules/licensing/LicenseCreatorModule.sol";
import "contracts/hooks/TokenGatedHook.sol";
import "contracts/modules/base/HookRegistry.sol";
import "contracts/interfaces/hooks/base/IHook.sol";
import { TokenGated } from "contracts/lib/hooks/TokenGated.sol";
import "test/foundry/mocks/MockERC721.sol";

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
     address licenseCreatorModule;
     address tokenGatedHook;
     address mockNFT;

     string constant NON_COMMERCIAL_LICENSE_URI = "https://noncommercial.license";
     string constant COMMERCIAL_LICENSE_URI = "https://commercial.license";

     constructor() JsonDeploymentHandler("main") {
     }

     /// @dev To use, run the following command (e.g. for Sepolia):
     /// forge script script/Main.s.sol:Main --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
    
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
                 bytes4(keccak256(bytes("initialize(address)"))), admin
             )
         );
         _writeAddress(contractKey, newAddress);
         console.log(string.concat(contractKey, " deployed to:"), newAddress);

         accessControl = newAddress;

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
         newAddress = address(new LicenseRegistry(ipAssetRegistry, moduleRegistry));
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
                 bytes4(keccak256(bytes("initialize(address)"))), accessControl
             )
         );
         _writeAddress(contractKey, newAddress);
         console.log(string.concat(contractKey, " deployed to:"), newAddress);

         ipOrgController = newAddress;

         /// SPG
         contractKey = "StoryProtocol";

         console.log(string.concat("Deploying ", contractKey, "..."));
         newAddress = address(new StoryProtocol(IIPOrgController(ipOrgController), ModuleRegistry(moduleRegistry)));
         _writeAddress(contractKey, newAddress);
         console.log(string.concat(contractKey, " deployed to:"), newAddress);

         spg = newAddress;


         /// REGISTRATION_MODULE
         contractKey = "RegistrationModule";

         console.log(string.concat("Deploying ", contractKey, "..."));
         newAddress = address(new RegistrationModule(BaseModule.ModuleConstruction({
             ipaRegistry: IPAssetRegistry(ipAssetRegistry),
             moduleRegistry: ModuleRegistry(moduleRegistry),
             licenseRegistry: LicenseRegistry(licenseRegistry),
             ipOrgController: IPOrgController(ipOrgController)
         }), accessControl));
         _writeAddress(contractKey, newAddress);
         console.log(string.concat(contractKey, " deployed to:"), newAddress);

         registrationModule = newAddress;


         /// RELATIONSHIP_MODULE
         contractKey = "RelationshipModule";

         console.log(string.concat("Deploying ", contractKey, "..."));
         newAddress = address(new RelationshipModule(BaseModule.ModuleConstruction({
             ipaRegistry: IPAssetRegistry(ipAssetRegistry),
             moduleRegistry: ModuleRegistry(moduleRegistry),
             licenseRegistry: LicenseRegistry(licenseRegistry),
             ipOrgController: IPOrgController(ipOrgController)
         }), accessControl));
         _writeAddress(contractKey, newAddress);
         console.log(string.concat(contractKey, " deployed to:"), newAddress);

         relationshipModule = newAddress;


         /// LICENSE_MODULE
         contractKey = "LicenseCreatorModule";

         console.log(string.concat("Deploying ", contractKey, "..."));
         newAddress = address(new LicenseCreatorModule(BaseModule.ModuleConstruction({
             ipaRegistry: IPAssetRegistry(ipAssetRegistry),
             moduleRegistry: ModuleRegistry(moduleRegistry),
             licenseRegistry: LicenseRegistry(licenseRegistry),
             ipOrgController: IPOrgController(ipOrgController)
         })));
         _writeAddress(contractKey, newAddress);
         console.log(string.concat(contractKey, " deployed to:"), newAddress);

         licenseCreatorModule = newAddress;


         /// TOKEN_GATED_HOOK
         contractKey = "TokenGatedHook";

         console.log(string.concat("Deploying ", contractKey, "..."));
         newAddress = address(new TokenGatedHook(accessControl));
         _writeAddress(contractKey, newAddress);
         console.log(string.concat(contractKey, " deployed to:"), newAddress);

         tokenGatedHook = newAddress;

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
         AccessControlSingleton accessControlSingleton = AccessControlSingleton(accessControl);
         accessControlSingleton.grantRole(AccessControl.UPGRADER_ROLE, admin);
         accessControlSingleton.grantRole(AccessControl.RELATIONSHIP_MANAGER_ROLE, admin);
         accessControlSingleton.grantRole(AccessControl.LICENSING_MANAGER_ROLE, admin);
         accessControlSingleton.grantRole(AccessControl.IPORG_CREATOR_ROLE, admin);
         accessControlSingleton.grantRole(AccessControl.MODULE_REGISTRAR_ROLE, admin);
         accessControlSingleton.grantRole(AccessControl.MODULE_EXECUTOR_ROLE, spg);

         // REGISTER MODULES
         ModuleRegistry(moduleRegistry).registerProtocolModule(
             ModuleRegistryKeys.REGISTRATION_MODULE, BaseModule(registrationModule));
         ModuleRegistry(moduleRegistry).registerProtocolModule(
             ModuleRegistryKeys.RELATIONSHIP_MODULE, BaseModule(relationshipModule));
         ModuleRegistry(moduleRegistry).registerProtocolModule(
             ModuleRegistryKeys.LICENSING_MODULE, BaseModule(licenseCreatorModule));
         string[] memory ipAssetTypes = new string[](2);
         ipAssetTypes[0] = "STORY";
         ipAssetTypes[1] = "CHARACTER";
         address ipOrg = StoryProtocol(spg).registerIpOrg(admin, "Sample IP Org", "SIPO", ipAssetTypes);

         // REGISTER TOKEN_GATED_HOOK
         address[] memory hooks = new address[](1);
         hooks[0] = tokenGatedHook;

         TokenGated.Config memory tokenGatedConfig = TokenGated.Config({
            tokenAddress: mockNFT
         });
         bytes[] memory hooksConfig = new bytes[](1);
         hooksConfig[0] = abi.encode(tokenGatedConfig);
         RegistrationModule(registrationModule).registerHooks(HookRegistry.HookType.PreAction, IIPOrg(ipOrg), hooks, hooksConfig);

         _writeDeployment();
         _endBroadcast();
     }
    
 }
