// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "contracts/IPAsset.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/modules/relationships/IRelationshipModule.sol";

contract SetTestRelationship is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    ProtocolRelationshipModule protocolRelationshipModule;

    constructor() JsonDeploymentHandler("") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();
        address relModule = _readAddress("ProtocolRelationshipModule-Proxy");
        if (relModule == address(0)) {
            revert("ProtocolRelationshipModule-Proxy not found");
        }
        protocolRelationshipModule = ProtocolRelationshipModule(relModule);

        bytes32 relationshipId = keccak256("TEST_RELATIONSHIP");

        IPAsset[] memory allIPAssets = new IPAsset[](7);
        for (uint8 i = 1; i <= 6; i++) {
            allIPAssets[i] = IPAsset(i);
        }

        address processor = _readAddress("PermissionlessRelationshipProcessor");
        if (processor == address(0)) {
            revert("PermissionlessRelationshipProcessor");
        }

        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIPAssets: allIPAssets,
            allowedExternalSource: true,
            destIPAssets: allIPAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: processor,
            disputer: admin,
            timeConfig: IRelationshipModule.TimeConfig({
                maxTTL: 0,
                minTTL: 0,
                renewable: false
            })
        });
        
        protocolRelationshipModule.setRelationshipConfig(relationshipId, params);
        
    }

}
