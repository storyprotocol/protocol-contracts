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
import "contracts/access-control/ProtocolRoles.sol";

contract Main is Script, BroadcastManager, JsonDeploymentHandler, ProxyHelper {

    using StringUtil for uint256;
    using stdJson for string;

    address ipAssetsFactory;
    address accessControl;
    address franchiseRegistry;
    address commonIPAssetEventEmitter;

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

        /// UPDATE BEACON

        contractKey = "IPAssetRegistry-Template";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new IPAssetRegistry(commonIPAssetEventEmitter));
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
        accessControlSingleton.grantRole(UPGRADER_ROLE, admin);
        accessControlSingleton.grantRole(RELATIONSHIP_MANAGER_ROLE, admin);
        
        _writeDeployment(); 
        _endBroadcast();
    }

}
