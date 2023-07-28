// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "contracts/IPAsset.sol";
import "contracts/modules/relationships/ProtocolRelationshipModule.sol";
import "contracts/modules/relationships/IRelationshipModule.sol";

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

        IPAsset[] memory sourceIPAssets = new IPAsset[](4);
        sourceIPAssets[0] = IPAsset.CHARACTER;
        sourceIPAssets[1] = IPAsset.GROUP;
        sourceIPAssets[2] = IPAsset.LOCATION;
        sourceIPAssets[3] = IPAsset.ITEM;
        
        IPAsset[] memory destIPAssets = new IPAsset[](1);
        destIPAssets[0] = IPAsset.STORY;

        address processor = _readAddress(".relationship-processors.SrcRequestOrDstOwnerRelationshipProcessor");
        if (processor == address(0)) {
            revert("SrcRequestOrDstOwnerRelationshipProcessor not found");
        }

        IRelationshipModule.SetRelationshipConfigParams memory params = IRelationshipModule.SetRelationshipConfigParams({
            sourceIPAssets: sourceIPAssets,
            allowedExternalSource: false,
            destIPAssets: destIPAssets,
            allowedExternalDest: false,
            onlySameFranchise: true,
            processor: processor,
            disputer: admin,
            timeConfig: IRelationshipModule.TimeConfig({
                maxTTL: 0,
                minTTL: 0,
                renewable: false
            })
        });
        
        protocolRelationshipModule.setRelationshipConfig("APPEARS_IN", params);
        
    }

}
