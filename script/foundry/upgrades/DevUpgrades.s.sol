// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/modules/relationships/RelationshipModuleBase.sol";
import "contracts/IPAssetController.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/ip-assets/IPAssetGroup.sol";


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
        address ipAssetControllerProxy = _readAddress(".main.IPAssetController-Proxy");

         
        address newProtocolRelationship = address(new ProtocolRelationshipModule(ipAssetControllerProxy));
        console.log("Upgrading ProtocolRelationshipModule to ", newProtocolRelationship);
        relModule.upgradeTo(newProtocolRelationship);
        console.log("Upgraded");
        
    }

}

contract UpgradeIPAssetController is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    constructor() JsonDeploymentHandler("main") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();

        address ipAssetControllerProxy = _readAddress(".main.IPAssetController-Proxy");
        address ipAssetRegistryFactory = _readAddress(".main.IPAssetGroupFactory");
        if (address(ipAssetRegistryFactory) == address(0)) {
            revert("ipAssetRegistryFactory not found");
        }

        IPAssetController ipAssetController = IPAssetController(ipAssetControllerProxy);
        address newIPAssetController = address(new IPAssetController());
        console.log("Upgrading IPAssetController to ", newIPAssetController);
        ipAssetController.upgradeTo(newIPAssetController);

        console.log("Upgrading IPAssetGroupFactory to ", newIPAssetController);
    }

}
/**
contract UpgradeIPAssetGroup is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    constructor() JsonDeploymentHandler("main") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();

        address ipAssetControllerProxy = _readAddress(".main.IPAssetController-Proxy");
        address ipAssetRegistryFactory = _readAddress(".main.IPAssetGroupFactory");
        if (address(ipAssetRegistryFactory) == address(0)) {
            revert("ipAssetRegistryFactory not found");
        }

        contractKey = "IPAssetGroup-Impl";
        console.log(string.concat("Deploying ", contractKey, "..."));
        address ipAssetRegistry = address(new IPAssetGroup(eventEmitter, ipAssetControllerProxy));
        console.log(string.concat(contractKey, " deployed to:"), ipAssetRegistry);

        console.log(string.concat("Updating ", contractKey, " beacon..."));
        IPAssetGroupFactory(ipAssetRegistryFactory).upgradeIPAssetGroups(ipAssetRegistry);
        console.log(string.concat(contractKey, " beacon updated to:"), ipAssetRegistry);
        
    }

}
*/
