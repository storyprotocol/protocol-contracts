// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.19;

import 'test/foundry/utils/ProxyHelper.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { AccessControlSingleton } from "contracts/access-control/AccessControlSingleton.sol";
import { Vm } from "forge-std/Test.sol";
import "forge-std/console.sol";

/// @title AccessControlHelper
/// @notice Helper contract to setup AccessControlSingleton and grant roles
contract AccessControlHelper is ProxyHelper {

    AccessControlSingleton accessControl;
    address admin = address(123);

    constructor() {}

    function _setupAccessControl() internal {
        // Create Access Control
        address accessControlSingletonImpl = address(new AccessControlSingleton());
        accessControl = AccessControlSingleton(
            _deployUUPSProxy(
                accessControlSingletonImpl,
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("initialize(address)"))), admin
                )
            )
        );
    }

    function _grantRole(Vm vm, bytes32 role, address account) internal {
        vm.prank(admin);
        accessControl.grantRole(role, account);
    }

}
