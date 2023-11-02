// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "contracts/lib/IPAsset.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import { Relationship } from "contracts/lib/modules/Relationship.sol";

contract SetAppearsInRelationship is Script, BroadcastManager, JsonDeploymentHandler {

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

        IPAsset.IPAssetType[] memory sourceIPAssets = new IPAsset.IPAssetType[](4);
        sourceIPAssets[0] = IPAsset.IPAssetType.CHARACTER;
        sourceIPAssets[1] = IPAsset.IPAssetType.GROUP;
        sourceIPAssets[2] = IPAsset.IPAssetType.LOCATION;
        sourceIPAssets[3] = IPAsset.IPAssetType.ITEM;
        
        IPAsset.IPAssetType[] memory destIPAssets = new IPAsset.IPAssetType[](1);
        destIPAssets[0] = IPAsset.IPAssetType.STORY;

        address processor = _readAddress(".relationship-processors.SrcRequestOrDstOwnerRelationshipProcessor");
        if (processor == address(0)) {
            revert("SrcRequestOrDstOwnerRelationshipProcessor not found");
        }

        Relationship.SetRelationshipConfigParams memory params = Relationship.SetRelationshipConfigParams({
            sourceIpAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIpAssets: destIPAssets,
            allowedExternalDest: false,
            onlySameIPOrg: true,
            processor: processor,
            disputer: admin,
            timeConfig: Relationship.TimeConfig({
                maxTtl: 0,
                minTtl: 0,
                renewable: false
            })
        });
        
        protocolRelationshipModule.setRelationshipConfig("APPEARS_IN", params);
        
    }

}
