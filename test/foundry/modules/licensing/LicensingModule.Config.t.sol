// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/lib/modules/LibRelationship.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract LicensingModuleConfigTest is BaseTest {
    using ShortStrings for *;

    function setUp() public override {
        super.setUp();
        Licensing.ParamDefinition[] memory params = new Licensing.ParamDefinition[](3);
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
        params[2] = Licensing.ParamDefinition({
            tag: "TEST_TAG_3".toShortString(),
            paramType: Licensing.ParameterType.Address,
            defaultValue: abi.encode(0x4545),
            availableChoices: ""
        });
        Licensing.SetFramework memory framework = Licensing.SetFramework({
            id: "test_framework",
            textUrl: "text_url",
            paramDefs: params
        });
        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(framework);
    }

    function test_LicensingModule_configIpOrg_revertIfNotIpOrgOwner() public {
        Licensing.LicensingConfig memory config = Licensing.LicensingConfig({
            frameworkId: "test_framework",
            params: new Licensing.ParamValue[](0),
            licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
        });
        vm.expectRevert(Errors.LicensingModule_CallerNotIpOrgOwner.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            config
        );
    }


    function test_LicensingModule_configIpOrg_revert_InvalidLicensorConfig()
        public
    {
        Licensing.LicensingConfig memory config = Licensing.LicensingConfig({
            frameworkId: "test_framework",
            params: new Licensing.ParamValue[](0),
            licensor: Licensing.LicensorConfig.Unset
        });
        vm.prank(ipOrg.owner());
        vm.expectRevert(Errors.LicensingModule_InvalidLicensorConfig.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            config
        );
    }

    function test_LicensingModule_configIpOrg_revert_paramLengthNotValid() public {
        Licensing.LicensingConfig memory config = Licensing.LicensingConfig({
            frameworkId: "test_framework",
            params: new Licensing.ParamValue[](1000),
            licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
        });
        vm.prank(ipOrg.owner());
        vm.expectRevert(Errors.LicensingModule_InvalidParamsLength.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            config
        );
    }

    function test_LicensingModule_configIpOrg() public {
        Licensing.ParamValue[] memory params = new Licensing.ParamValue[](3);
        params[0] = Licensing.ParamValue({
            tag: "TEST_TAG_1".toShortString(),
            value: abi.encode(true)
        });
        params[1] = Licensing.ParamValue({
            tag: "TEST_TAG_2".toShortString(),
            value: abi.encode(222)
        });
        ShortString[] memory ssValue = new ShortString[](2);
        ssValue[0] = "test1".toShortString();
        ssValue[1] = "test2".toShortString();
        params[2] = Licensing.ParamValue({
            tag: "TEST_TAG_3".toShortString(),
            value: abi.encode(ssValue)
        });

        Licensing.LicensingConfig memory config = Licensing.LicensingConfig({
            frameworkId: "test_framework",
            params: params,
            licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
        });
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            config
        );
        assertEq(
            uint8(licensingModule.getIpOrgLicensorConfig(address(ipOrg))),
            uint8(Licensing.LicensorConfig.IpOrgOwnerAlways)
        );
        assertEq(
            licensingModule.getIpOrgValueForParam(address(ipOrg), "TEST_TAG_1"),
            abi.encode(true)
        );
        assertEq(
            licensingModule.getIpOrgValueForParam(address(ipOrg), "TEST_TAG_2"),
            abi.encode(222)
        );
        assertEq(
            licensingModule.getIpOrgValueForParam(address(ipOrg), "TEST_TAG_3"),
            abi.encode(ssValue)
        );
    }

    function test_LicensingModule_configIpOrg_revert_ipOrgAlreadySet() public {
        test_LicensingModule_configIpOrg();
        Licensing.ParamValue[] memory params = new Licensing.ParamValue[](1);
        params[0] = Licensing.ParamValue({
            tag: "TEST_TAG_1".toShortString(),
            value: abi.encode(true)
        });

        Licensing.LicensingConfig memory config = Licensing.LicensingConfig({
            frameworkId: "test_framework",
            params: params,
            licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
        });
        vm.prank(ipOrg.owner());
        vm.expectRevert(Errors.LicensingModule_IpOrgFrameworkAlreadySet.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            config
        );
    }
}
