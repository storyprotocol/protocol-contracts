// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "test/foundry/utils/ProxyHelper.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "contracts/modules/relationships/processors/PermissionlessRelationshipProcessor.sol";
import "contracts/modules/relationships/processors/DstOwnerRelationshipProcessor.sol";
import "contracts/modules/relationships/processors/SrcOwnerRelationshipProcessor.sol";
import "contracts/modules/relationships/processors/SrcDstOwnerRelationshipProcessor.sol";

contract RelationshipProcessors is Script, BroadcastManager, JsonDeploymentHandler, ProxyHelper {

    using StringUtil for uint256;
    using stdJson for string;
    address relationshipModule;

    constructor() JsonDeploymentHandler("relationships-processors") {
    }

    function run() public {
        _beginBroadcast();
        _readDeployment();
        
        relationshipModule = _readAddress("$.main.ProtocolRelationshipModule-Proxy");
        if (relationshipModule == address(0)) {
            revert("ProtocolRelationshipModule-Proxy not found");
        }

        string memory contractKey;
        address newAddress;
        
        /// PERMISSIONLESS
        contractKey = "PermissionlessRelationshipProcessor";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new PermissionlessRelationshipProcessor(relationshipModule));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);
        
        /// DST OWNER
        contractKey = "DstOwnerRelationshipProcessor";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new DstOwnerRelationshipProcessor(relationshipModule));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        /// SRC OWNER
        contractKey = "SrcOwnerRelationshipProcessor";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new SrcOwnerRelationshipProcessor(relationshipModule));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);

        /// SRC DST OWNER
        contractKey = "SrcDstOwnerRelationshipProcessor";

        console.log(string.concat("Deploying ", contractKey, "..."));
        newAddress = address(new SrcDstOwnerRelationshipProcessor(relationshipModule));
        _writeAddress(contractKey, newAddress);
        console.log(string.concat(contractKey, " deployed to:"), newAddress);


        _writeDeployment(); 
        _endBroadcast();
    }

}
