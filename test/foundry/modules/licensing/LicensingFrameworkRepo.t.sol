/* solhint-disable contract-name-camelcase, func-name-mixedcase */
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

    LicensingFrameworkRepo internal repo;

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
            paramType: Licensing.ParameterType.Bool,
            defaultValue: abi.encode(true),
            availableChoices: ""
        });
        params[1] = Licensing.ParamDefinition({
            tag: "TEST_TAG_2".toShortString(),
            paramType: Licensing.ParameterType.Number,
            defaultValue: abi.encode(123),
            availableChoices: ""
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
        assertEq(abi.encode(true), param1.defaultValue);
        Licensing.ParamDefinition memory param2 = repo.getParamDefinitionAt("test_id", 1);
        assertTrue(ShortStringOps._equal("TEST_TAG_2".toShortString(), param2.tag));
        assertEq(uint8(Licensing.ParameterType.Number), uint8(param2.paramType));
        assertEq(abi.encode(123), param2.defaultValue);
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

    function test_LicensingFrameworkRepovalidateParamValue_Bool() public {
        Licensing.ParamDefinition memory pDef = Licensing.ParamDefinition({
            tag: "TEST_TAG".toShortString(),
            paramType: Licensing.ParameterType.Bool,
            defaultValue: abi.encode(true),
            availableChoices: ""
        });
        assertTrue(Licensing.validateParamValue(pDef, abi.encode(true)));
        assertTrue(Licensing.validateParamValue(pDef, abi.encode(false)));
        // WARNING: we cant prevent this
        assertTrue(Licensing.validateParamValue(pDef, abi.encode(1)));
        vm.expectRevert();
        Licensing.validateParamValue(pDef, abi.encode("test"));
    }

    function test_LicensingFrameworkRepo_validateParam_emptyValue() public {
        Licensing.ParamDefinition memory pDef = Licensing.ParamDefinition({
            tag: "TEST_TAG".toShortString(),
            paramType: Licensing.ParameterType.ShortStringArray,
            defaultValue: "",
            availableChoices: ""
        });
        assertTrue(Licensing.validateParamValue(pDef, ""));
    }

    function test_LicensingFrameworkRepovalidateParamValue_Number() public {
        Licensing.ParamDefinition memory pDef = Licensing.ParamDefinition({
            tag: "TEST_TAG".toShortString(),
            paramType: Licensing.ParameterType.Number,
            defaultValue: abi.encode(123),
            availableChoices: ""
        });
        assertTrue(Licensing.validateParamValue(pDef, abi.encode(1123123)));
        //WARNING: everyting can be decoded as a number
       
    }

    function test_LicensingFrameworkRepovalidateParamValue_Address() public {
        Licensing.ParamDefinition memory pDef = Licensing.ParamDefinition({
            tag: "TEST_TAG".toShortString(),
            paramType: Licensing.ParameterType.Address,
            defaultValue: abi.encode(0x123),
            availableChoices: ""
        });
        assertTrue(Licensing.validateParamValue(pDef, abi.encode(address(0x123))));
        assertFalse(Licensing.validateParamValue(pDef, abi.encode(address(0))));
    }

    function test_LicensingFrameworkRepovalidateParamValue_String() public {
        Licensing.ParamDefinition memory pDef = Licensing.ParamDefinition({
            tag: "TEST_TAG".toShortString(),
            paramType: Licensing.ParameterType.String,
            defaultValue: abi.encode("test"),
            availableChoices: ""
        });
        assertTrue(Licensing.validateParamValue(pDef, abi.encode("test")), "string is true");
        assertFalse(Licensing.validateParamValue(pDef, ""), "empty value is false");
        assertFalse(Licensing.validateParamValue(pDef, abi.encode("")), "empty string is false");
        assertFalse(Licensing.validateParamValue(pDef, abi.encode(" ")), "space is false");
        vm.expectRevert();
        Licensing.validateParamValue(pDef, abi.encode(123));
    }

    function test_LicensingFrameworkRepovalidateParamValue_ShortStringArray() public {
        ShortString[] memory ssValue = new ShortString[](2);
        ssValue[0] = "test1".toShortString();
        ssValue[1] = "test2".toShortString();
        Licensing.ParamDefinition memory pDef = Licensing.ParamDefinition({
            tag: "TEST_TAG".toShortString(),
            paramType: Licensing.ParameterType.ShortStringArray,
            defaultValue: abi.encode(ssValue),
            availableChoices: ""
        });
        assertTrue(Licensing.validateParamValue(pDef, abi.encode(ssValue)));
        vm.expectRevert();
        Licensing.validateParamValue(pDef, abi.encode(["test", "tttest"]));
    }

    function test_LicensingFrameworkRepovalidateParamValue_MultipleChoice() public {
        ShortString[] memory ssValue = new ShortString[](2);
        ssValue[0] = "test1".toShortString();
        ssValue[1] = "test2".toShortString();
        Licensing.ParamDefinition memory pDef = Licensing.ParamDefinition({
            tag: "TEST_TAG".toShortString(),
            paramType: Licensing.ParameterType.MultipleChoice,
            defaultValue: abi.encode(0),
            availableChoices: abi.encode(ssValue)
        });

        assertTrue(Licensing.validateParamValue(pDef, abi.encode(0x1)));

    }
    
}
