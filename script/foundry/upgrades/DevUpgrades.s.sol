// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/modules/relationships/RelationshipModuleBase.sol";
import "contracts/IPAssetOrgFactory.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import "contracts/ip-assets/IPAssetOrg.sol";


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
        address franchiseProxy = _readAddress(".main.IPAssetOrgFactory-Proxy");

         
        address newProtocolRelationship = address(new ProtocolRelationshipModule(franchiseProxy));
        console.log("Upgrading ProtocolRelationshipModule to ", newProtocolRelationship);
        relModule.upgradeTo(newProtocolRelationship);
        console.log("Upgraded");
        
    }

}

contract UpgradeIPAssetOrgFactory is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    constructor() JsonDeploymentHandler("main") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();

        address franchiseProxy = _readAddress(".main.IPAssetOrgFactory-Proxy");
        address ipAssetOrgFactory = _readAddress(".main.IPAssetOrgFactory");
        if (address(ipAssetOrgFactory) == address(0)) {
            revert("ipAssetOrgFactory not found");
        }

        IPAssetOrgFactory franchise = IPAssetOrgFactory(franchiseProxy);
        address newIPAssetOrgFactory = address(new IPAssetOrgFactory());
        console.log("Upgrading IPAssetOrgFactory to ", newIPAssetOrgFactory);
        franchise.upgradeTo(newIPAssetOrgFactory);

        console.log("Upgrading IPAssetOrgFactory to ", newIPAssetOrgFactory);
    }

}
/**
contract UpgradeIPAssetOrg is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    constructor() JsonDeploymentHandler("main") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();

        address franchiseProxy = _readAddress(".main.IPAssetOrgFactory-Proxy");
        address ipAssetOrgFactory = _readAddress(".main.IPAssetOrgFactory");
        if (address(ipAssetOrgFactory) == address(0)) {
            revert("ipAssetOrgFactory not found");
        }

        contractKey = "IPAssetOrg-Impl";
        console.log(string.concat("Deploying ", contractKey, "..."));
        address ipAssetOrg = address(new IPAssetOrg(eventEmitter, franchiseProxy));
        console.log(string.concat(contractKey, " deployed to:"), ipAssetOrg);

        console.log(string.concat("Updating ", contractKey, " beacon..."));
        IPAssetOrgFactory(ipAssetOrgFactory).upgradeIPAssetOrgs(ipAssetRegistry);
        console.log(string.concat(contractKey, " beacon updated to:"), ipAssetOrg);
        
    }

}
*/
