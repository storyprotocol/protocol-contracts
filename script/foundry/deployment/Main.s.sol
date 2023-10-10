// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "test/foundry/utils/ProxyHelper.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "contracts/ip-assets/IPAssetRegistryFactory.sol";
import "contracts/ip-assets/IPAssetRegistry.sol";
import "contracts/ip-assets/events/CommonIPAssetEventEmitter.sol";
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/modules/licensing/LicensingModule.sol";
import "test/foundry/mocks/MockCollectNFT.sol";
import "test/foundry/mocks/MockCollectModule.sol";
import "contracts/modules/royalties/RoyaltyDistributor.sol";
import "contracts/modules/royalties/policies/MutableRoyaltyProportionPolicy.sol";
import "contracts/modules/royalties/RoyaltyNFT.sol";
import "contracts/ip-accounts/IPAccountImpl.sol";
import "contracts/ip-accounts/IPAccountRegistry.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";

contract Main is Script, BroadcastManager, JsonDeploymentHandler, ProxyHelper {

    using StringUtil for uint256;
    using stdJson for string;

    address ipAssetsFactory;
    address accessControl;
    address franchiseRegistry;
    address commonIPAssetEventEmitter;

    string constant NON_COMMERCIAL_LICENSE_URI = "https://noncommercial.license";
    string constant COMMERCIAL_LICENSE_URI = "https://commercial.license";

    constructor() JsonDeploymentHandler("main") {
    }

    /// @dev To use, run the following command (e.g. for Goerli):
    /// forge script script/Deploy.s.sol:Deploy --rpc-url $GOERLI_RPC_URL --broadcast --verify -vvvv
    
    function run() public {
        _beginBroadcast();
        string memory contractKey;
        address newAddress;
        
        /// IP ASSETS REGISTRY FACTORY
        contractKey = "IPAssetRegistryFactory";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new IPAssetRegistryFactory());
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);
        
        ipAssetsFactory = newAddress;

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

        /// FRANCHISE REGISTRY
        contractKey = "FranchiseRegistry-Impl";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new FranchiseRegistry(ipAssetsFactory));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        contractKey = "FranchiseRegistry-Proxy";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = _deployUUPSProxy(
            newAddress,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("initialize(address)"))), accessControl
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        franchiseRegistry = newAddress;

        /// COMMON EVENT EMITTER
        contractKey = "CommonIPAssetEventEmitter";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new CommonIPAssetEventEmitter(franchiseRegistry));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        commonIPAssetEventEmitter = newAddress;


        /// LICENSING MODULE
        contractKey = "LicensingModule-Impl";

        console.log(string.concat("Deploying ", contractKey, "..."));

        newAddress = address(new LicensingModule(address(franchiseRegistry)));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        contractKey = "LicensingModule-Proxy";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = _deployUUPSProxy(
            newAddress,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("initialize(address,string)"))),
                accessControl, NON_COMMERCIAL_LICENSE_URI
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);
        address licensingModule = newAddress;

        /// COLLECT MODULE
        contractKey = "CollectNFT";
        console.log(string.concat("Deploying ", contractKey, "..."));

        newAddress = address(new MockCollectNFT());
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        address defaultCollectNFTImpl = newAddress;

        contractKey = "CollectModule-Impl";
        console.log(string.concat("Deploying ", contractKey, "..."));

        newAddress = address(new MockCollectModule(address(franchiseRegistry), defaultCollectNFTImpl));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        contractKey = "CollectModule-Proxy";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = _deployUUPSProxy(
            newAddress,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("initialize(address)"))), address(accessControl)
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);
        address collectModule = newAddress;


        /// IP ACCOUNT REGISTRY
        contractKey = "IPAccount-Impl";
        console.log(string.concat("Deploying ", contractKey, "..."));

        newAddress = address(new IPAccountImpl());
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        contractKey = "IPAccountRegistry";
        console.log(string.concat("Deploying ", contractKey, "..."));

        newAddress = address(new IPAccountRegistry(newAddress));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        address ipAccountRegistry = newAddress;

        /// ROYALTY MODULE
        address SPLIT_MAIN = 0x2ed6c4B5dA6378c7897AC67Ba9e43102Feb694EE;
        contractKey = "RoyaltyNFT";
        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new RoyaltyNFT(SPLIT_MAIN));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        address royaltyNft = newAddress;

        contractKey = "MutableRoyaltyProportionPolicy";
        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new MutableRoyaltyProportionPolicy(royaltyNft));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        contractKey = "RoyaltyDistributor";
        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new RoyaltyDistributor(ipAccountRegistry, royaltyNft));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        /// UPDATE BEACON

        contractKey = "IPAssetRegistry-Template";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(
            new IPAssetRegistry(
                commonIPAssetEventEmitter,
                licensingModule,
                franchiseRegistry,
                collectModule
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        console.log(string.concat("Updating ", contractKey, " beacon..."));
        IPAssetRegistryFactory(ipAssetsFactory).upgradeFranchises(newAddress);
        console.log(string.concat(contractKey, " beacon updated to:"), newAddress);


        /// PROTOCOL RELATIONSHIP MODULE
        contractKey = "ProtocolRelationshipModule-Impl";
       
        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new ProtocolRelationshipModule(franchiseRegistry));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);
        

        contractKey = "ProtocolRelationshipModule-Proxy";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = _deployUUPSProxy(
            newAddress,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("initialize(address)"))), accessControl
            )
        );
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);


        /// GRANT ROLEs
        AccessControlSingleton accessControlSingleton = AccessControlSingleton(accessControl);
        accessControlSingleton.grantRole(AccessControl.UPGRADER_ROLE, admin);
        accessControlSingleton.grantRole(AccessControl.RELATIONSHIP_MANAGER_ROLE, admin);
        
        _writeDeployment(); 
        _endBroadcast();
    }
    
}
