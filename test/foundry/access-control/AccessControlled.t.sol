// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { AccessControlHelper } from "test/foundry/utils/AccessControlHelper.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { AccessControlled } from "contracts/access-control/AccessControlled.sol";
import { AccessControlSingleton } from "contracts/access-control/AccessControlSingleton.sol";
import { MockAccessControlled } from "test/foundry/mocks/MockAccessControlled.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract AccessControlledTest is Test, AccessControlHelper {

    event AccessControlUpdated(address indexed accessControl);

    MockAccessControlled accessControlled;

    function setUp() public {
        _setupAccessControl();
        accessControlled = new MockAccessControlled(address(accessControl));
    }

    function test_AccessControlled_onlyRole() public {
        bytes32 role = keccak256("TEST_ROLE");
        _grantRole(vm, role, address(this));
        accessControlled.exposeOnlyRole(role);
    }

    function test_AccessControlled_revert_onlyRole() public {
        bytes32 role = keccak256("TEST_ROLE");
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.MissingRole.selector,
                role,
                address(this)
            )
        );
        accessControlled.exposeOnlyRole(role);
    }

    function test_AccessControlled_setAccessControl() public {
        AccessControlSingleton ac2 = new AccessControlSingleton();
        vm.expectEmit(true, true, true, true);
        emit AccessControlUpdated(address(ac2));
        vm.prank(admin);
        accessControlled.setAccessControl(address(ac2));
    }

    function test_AccessControlled_revert_setAccessControlNotProtocolAdmin() public {
        AccessControlSingleton ac2 = new AccessControlSingleton();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.MissingRole.selector,
                AccessControl.PROTOCOL_ADMIN_ROLE,
                address(this)
            )
        );
        accessControlled.setAccessControl(address(ac2));
    }

    function test_AccessControlled_revert_setAccessControlUnsupportedInterface() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.UnsupportedInterface.selector,
                "IAccessControl"
            )
        );
        vm.prank(admin);
        accessControlled.setAccessControl(address(this));
    }
}
