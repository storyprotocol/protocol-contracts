// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "contracts/IPAsset.sol";
import "contracts/access-control/AccessControlSingleton.sol";
import { RELATIONSHIP_MANAGER_ROLE } from "contracts/access-control/ProtocolRoles.sol";

contract GrantRole is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    bytes32 constant ROLE = RELATIONSHIP_MANAGER_ROLE;
    address constant GRANTEE = 0xB6288e57bf7406B35ab4F70Fd1135E907107e386;

    constructor() JsonDeploymentHandler("") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();
        address moduleAddress = _readAddress(".main.AccessControlSingleton-Proxy");
        if (moduleAddress == address(0)) {
            revert("AccessControlSingleton-Proxy not found");
        }
        AccessControlSingleton access = AccessControlSingleton(moduleAddress);
        access.grantRole(ROLE, GRANTEE);
    }

}
