// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/modules/relationships/RelationshipModuleBase.sol";
import "contracts/FranchiseRegistry.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/access-control/ProtocolRoles.sol";
import "contracts/ip-assets/events/CommonIPAssetEventEmitter.sol";
import "contracts/ip-assets/IPAssetRegistry.sol";

/**
 * Use to upgrade contracts during development, in testnets. Expect things to break.
 */
contract UpgradeRelationships is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    constructor() JsonDeploymentHandler("main") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();
        
        ProtocolRelationshipModule relModule = ProtocolRelationshipModule(_readAddress(".main.ProtocolRelationshipModule-Proxy"));
        if (address(relModule) == address(0)) {
            revert("ProtocolRelationshipModule-Proxy not found");
        }
        address franchiseRegistryProxy = _readAddress(".main.FranchiseRegistry-Proxy");

         
        address newProtocolRelationship = address(new ProtocolRelationshipModule(franchiseRegistryProxy));
        console.log("Upgrading ProtocolRelationshipModule to ", newProtocolRelationship);
        relModule.upgradeTo(newProtocolRelationship);
        console.log("Upgraded");
        
    }

}

contract UpgradeFranchiseRegistry is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    constructor() JsonDeploymentHandler("main") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();

        address franchiseRegistryProxy = _readAddress(".main.FranchiseRegistry-Proxy");
        address ipAssetRegistryFactory = _readAddress(".main.IPAssetRegistryFactory");
        if (address(ipAssetRegistryFactory) == address(0)) {
            revert("ipAssetRegistryFactory not found");
        }

        FranchiseRegistry franchiseRegistry = FranchiseRegistry(franchiseRegistryProxy);
        address newFranchiseRegistry = address(new FranchiseRegistry(ipAssetRegistryFactory));
        console.log("Upgrading FranchiseRegistry to ", newFranchiseRegistry);
        franchiseRegistry.upgradeTo(newFranchiseRegistry);
        
    }

}

contract UpgradeIPAssetRegistry is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    constructor() JsonDeploymentHandler("main") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();

        address franchiseRegistryProxy = _readAddress(".main.FranchiseRegistry-Proxy");
        address ipAssetRegistryFactory = _readAddress(".main.IPAssetRegistryFactory");
        if (address(ipAssetRegistryFactory) == address(0)) {
            revert("ipAssetRegistryFactory not found");
        }

        string memory contractKey = "CommonEventEmitter";

        console.log(string.concat("Deploying ", contractKey, "..."));
        address eventEmitter = address(new CommonIPAssetEventEmitter(franchiseRegistryProxy));
        console.log(string.concat(contractKey, " deployed to:"), eventEmitter);

        contractKey = "IPAssetRegistry-Impl";
        console.log(string.concat("Deploying ", contractKey, "..."));
        address ipAssetRegistry = address(new IPAssetRegistry(eventEmitter, franchiseRegistryProxy));
        console.log(string.concat(contractKey, " deployed to:"), ipAssetRegistry);

        console.log(string.concat("Updating ", contractKey, " beacon..."));
        IPAssetRegistryFactory(ipAssetRegistryFactory).upgradeFranchises(ipAssetRegistry);
        console.log(string.concat(contractKey, " beacon updated to:"), ipAssetRegistry);
        
    }

}
