// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { AccessControlHelper } from "test/foundry/utils/AccessControlHelper.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { AccessControlSingleton } from "contracts/access-control/AccessControlSingleton.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract AccessControlSingletonTest is Test, AccessControlHelper {
    function setUp() public {
        _setupAccessControl();
    }

    function test_AccessControlSingleton_setup() public {
        assertTrue(
            accessControl.hasRole(AccessControl.PROTOCOL_ADMIN_ROLE, admin),
            "Admin role not set correctly"
        );
    }

    function test_AccessControlSingleton_revert_zeroAdmin() public {
        AccessControlSingleton ac2 = new AccessControlSingleton();
        vm.expectRevert(Errors.ZeroAddress.selector);
        ac2.initialize(address(0));
    }

    function test_AccessControlSingleton_setRoleAdmin() public {
        bytes32 role = keccak256("TEST_ROLE");
        bytes32 roleAdmin = keccak256("TEST_ROLE_ADMIN");
        vm.prank(admin);
        accessControl.setRoleAdmin(role, roleAdmin);
        assertTrue(
            accessControl.getRoleAdmin(role) == roleAdmin,
            "Role admin not set correctly"
        );
    }

    function test_AccessControlSingleton_revert_setRoleAdminNotProtocolAdmin() public {
        bytes32 role = keccak256("TEST_ROLE");
        vm.expectRevert(_getRoleErrorMessage(address(this), AccessControl.PROTOCOL_ADMIN_ROLE));
        accessControl.setRoleAdmin(role, AccessControl.PROTOCOL_ADMIN_ROLE);
    }

    function test_AccessControlSingleton_revert_UpgradeNotAuthorized() public {
        vm.expectRevert(_getRoleErrorMessage(address(this), AccessControl.UPGRADER_ROLE));
        accessControl.upgradeTo(address(0));
    }

    function _getRoleErrorMessage(address sender, bytes32 role) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "AccessControl: account ",
            Strings.toHexString(uint160(sender), 20),
            " is missing role ",
            Strings.toHexString(uint256(role), 32)
        );
    }


}
