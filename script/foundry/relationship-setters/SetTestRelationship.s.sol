// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "contracts/IPAsset.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/interfaces/modules/relationships/IRelationshipModule.sol";

contract SetTestRelationship is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    ProtocolRelationshipModule protocolRelationshipModule;

    constructor() JsonDeploymentHandler("") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();
        address relModule = _readAddress(".main.ProtocolRelationshipModule-Proxy");
        if (relModule == address(0)) {
            revert("ProtocolRelationshipModule-Proxy not found");
        }
        protocolRelationshipModule = ProtocolRelationshipModule(relModule);

        IPAsset[] memory allIpAssets = new IPAsset[](6);
        for (uint8 i = 0; i < 6; i++) {
            allIpAssets[i] = IPAsset(i + 1);
        }

        address processor = _readAddress(".relationship-processors.PermissionlessRelationshipProcessor");
        if (processor == address(0)) {
            revert("PermissionlessRelationshipProcessor");
        }

        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIpAssets: allIpAssets,
            allowedExternalSource: true,
            destIpAssets: allIpAssets,
            allowedExternalDest: true,
            onlySameFranchise: true,
            processor: processor,
            disputer: admin,
            timeConfig: IRelationshipModule.TimeConfig({
                maxTtl: 0,
                minTtl: 0,
                renewable: false
            })
        });
        
        protocolRelationshipModule.setRelationshipConfig("TEST_RELATIONSHIP", params);
        
    }

}
