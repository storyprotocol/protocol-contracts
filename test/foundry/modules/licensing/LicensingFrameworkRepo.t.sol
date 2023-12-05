// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { LicensingFrameworkRepo } from "contracts/modules/licensing/LicensingFrameworkRepo.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { AccessControlHelper } from "test/foundry/utils/AccessControlHelper.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";
import { Errors } from "contracts/lib/Errors.sol";

contract LicensingFrameworkRepoTest is Test, AccessControlHelper {
    using ShortStrings for *;

    LicensingFrameworkRepo repo;

    event RequestPending(address indexed sender);
    event RequestCompleted(address indexed sender);

    function setUp() public {
        _setupAccessControl();
        _grantRole(vm, AccessControl.LICENSING_MANAGER, admin);
        repo = new LicensingFrameworkRepo(address(accessControl));
    }

    function test_LicensingFrameworkRepo_addFramework() public {
        Licensing.ParamDefinition[] memory params = new Licensing.ParamDefinition[](2);
        params[0] = Licensing.ParamDefinition({
            tag: "TEST_TAG_1".toShortString(),
            paramType: Licensing.ParameterType.Bool
        });
        params[1] = Licensing.ParamDefinition({
            tag: "TEST_TAG_2".toShortString(),
            paramType: Licensing.ParameterType.Number
        });
        Licensing.SetFramework memory framework = Licensing.SetFramework({
            id: "test_id",
            textUrl: "text_url",
            paramDefs: params
        });
        vm.prank(admin);
        repo.addFramework(framework);
        assertEq("text_url", repo.getLicenseTextUrl("test_id"));
        assertEq(2, repo.getTotalParameters("test_id"));
        Licensing.ParamDefinition memory param1 = repo.getParamDefinitionAt("test_id", 0);
        assertTrue(ShortStringOps._equal("TEST_TAG_1".toShortString(), param1.tag));
        assertEq(uint8(Licensing.ParameterType.Bool), uint8(param1.paramType));
       
    }

    function test_LicensingFrameworkRepo_revert_addFrameworkNotLicensingManager() public {
        Licensing.SetFramework memory framework = Licensing.SetFramework({
            id: "test_id",
            textUrl: "text_url",
            paramDefs: new Licensing.ParamDefinition[](0)
        });
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.MissingRole.selector,
                AccessControl.LICENSING_MANAGER,
                address(this)
            )
        );
        repo.addFramework(framework);
    }

    function test_LicensingFrameworkRepo_validateParamValue_Bool() public {
        Licensing.ParameterType pType = Licensing.ParameterType.Bool;
        assertTrue(Licensing._validateParamValue(pType, abi.encode(true)));
        assertTrue(Licensing._validateParamValue(pType, abi.encode(false)));
        // WARNING: we cant prevent this
        assertTrue(Licensing._validateParamValue(pType, abi.encode(1)));
        vm.expectRevert();
        Licensing._validateParamValue(pType, abi.encode("test"));
    }

    function test_LicensingFrameworkRepo_validateParam_emptyValue() public {
        Licensing.ParameterType pType = Licensing.ParameterType.MultipleChoice;
        assertFalse(Licensing._validateParamValue(pType, ""));
    }

    function test_LicensingFrameworkRepo_validateParamValue_Number() public {
        Licensing.ParameterType pType = Licensing.ParameterType.Number;
        assertTrue(Licensing._validateParamValue(pType, abi.encode(uint256(1123123))));
        //WARNING: everyting can be decoded as a number
       
    }

    function test_LicensingFrameworkRepo_validateParamValue_Address() public {
        Licensing.ParameterType pType = Licensing.ParameterType.Address;
        assertTrue(Licensing._validateParamValue(pType, abi.encode(address(0x123))));
        assertFalse(Licensing._validateParamValue(pType, abi.encode(address(0))));
    }

    function test_LicensingFrameworkRepo_validateParamValue_String() public {
        Licensing.ParameterType pType = Licensing.ParameterType.String;
        assertTrue(Licensing._validateParamValue(pType, abi.encode("test")), "string is true");
        assertFalse(Licensing._validateParamValue(pType, ""), "empty value is false");
        assertFalse(Licensing._validateParamValue(pType, abi.encode("")), "empty string is false");
        assertFalse(Licensing._validateParamValue(pType, abi.encode(" ")), "space is false");
        vm.expectRevert();
        Licensing._validateParamValue(pType, abi.encode(123));
    }

    function test_LicensingFrameworkRepo_validateParamValue_MultipleChoice() public {
        Licensing.ParameterType pType = Licensing.ParameterType.MultipleChoice;
        ShortString[] memory ssValue = new ShortString[](2);
        ssValue[0] = "test1".toShortString();
        ssValue[1] = "test2".toShortString();
        assertTrue(Licensing._validateParamValue(pType, abi.encode(ssValue)));
        ShortString[] memory emptyValue = new ShortString[](0);
        assertFalse(Licensing._validateParamValue(pType, abi.encode(emptyValue)));
    }

    function test_LicensingFrameworkRepo_validateConfig() public {
        Licensing.ParamDefinition[] memory params = new Licensing.ParamDefinition[](3);
        params[0] = Licensing.ParamDefinition({
            tag: "TEST_TAG_1".toShortString(),
            paramType: Licensing.ParameterType.Bool
        });
        params[1] = Licensing.ParamDefinition({
            tag: "TEST_TAG_2".toShortString(),
            paramType: Licensing.ParameterType.Number
        });
        params[2] = Licensing.ParamDefinition({
            tag: "TEST_TAG_3".toShortString(),
            paramType: Licensing.ParameterType.String
        });
        Licensing.SetFramework memory framework = Licensing.SetFramework({
            id: "test_id",
            textUrl: "text_url",
            paramDefs: params
        });
        vm.prank(admin);
        repo.addFramework(framework);
        
        Licensing.ParamValue[] memory values = new Licensing.ParamValue[](2);
        values[0] = Licensing.ParamValue({
            tag: "TEST_TAG_1".toShortString(),
            value: abi.encode(true)
        });
        values[1] = Licensing.ParamValue({
            tag: "TEST_TAG_2".toShortString(),
            value: abi.encode(123213123)
        });
        assertTrue(repo.validateParamValues("test_id", values));
    }
    
}
