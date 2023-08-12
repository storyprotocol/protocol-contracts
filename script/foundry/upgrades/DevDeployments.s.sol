// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "test/foundry/utils/ProxyHelper.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/modules/relationships/RelationshipModuleBase.sol";
import "contracts/FranchiseRegistry.sol";
import "contracts/modules/licensing/LicensingModule.sol";

/**
 * Use to upgrade contracts during development, in testnets. Expect things to break.
 */
contract DeployLicenseModule is Script, BroadcastManager, JsonDeploymentHandler, ProxyHelper {

    using StringUtil for uint256;
    using stdJson for string;

    constructor() JsonDeploymentHandler("main") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();
        
        address franchiseRegistryProxy = _readAddress(".main.FranchiseRegistry-Proxy");

        
        /// ACCESS CONTROL SINGLETON
        string memory contractKey = "LicenseModule-Impl";

        console.log(string.concat("Deploying ", contractKey, "..."));
        address licenseModuleImpl = address(new LicensingModule(franchiseRegistryProxy));
        console.log(string.concat(contractKey, " deployed to:"), licenseModuleImpl);
        

        contractKey = "LicenseModule-Proxy";
        string memory noncommercialLicenseURL = "https://arweave.net/yHIbKlFBg3xuKSzlM_dREG8Y08uod-gWKsWi9OaPFsM";
        address accessControl = _readAddress(".main.AccessControlSingleton-Proxy");
        console.log(string.concat("Deploying ", contractKey, "..."));
        address proxy = _deployUUPSProxy(
            licenseModuleImpl,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("initialize(string,address)"))), noncommercialLicenseURL, accessControl
            )
        );
        
        console.log(string.concat(contractKey, " deployed to:"), proxy);
        
    }

}
