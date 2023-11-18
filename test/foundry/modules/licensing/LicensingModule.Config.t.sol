// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/lib/modules/LibRelationship.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { TermCategories, TermIds, TermsData } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { BaseLicensingTest, LicTestConfig } from "./BaseLicensingTest.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract LicensingModuleConfigTest is BaseLicensingTest {
    function setUp() public override {
        super.setUp();
    }

    function test_LicensingModule_configIpOrg_revertIfNotIpOrgOwner() public {
        vm.expectRevert(Errors.LicensingModule_CallerNotIpOrgOwner.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            _getFramework(false)
        );
    }

    function test_LicensingModule_configIpOrg_ipOrgWithoutCommercialTermsIsNonCommercial()
        public
        withNonCommFramework(LicTestConfig({
            shareAlike: true,
            licConfig: TermsData.LicensorConfig.IpOrg,
            needsActivation: false
        }))
    {
        assertFalse(licensingModule.ipOrgAllowsCommercial(address(ipOrg)), "should be non commercial");
        (
            ShortString[] memory comTermIds,
            bytes[] memory comTermData
        ) = licensingModule.getIpOrgTerms(true, address(ipOrg));
        assertTrue(comTermIds.length == 0, "commercial terms should be empty");
        assertTermsSetInIpOrg(false);// non commercial terms
    }

    function test_LicensingModule_configIpOrg_ipOrgWithCommercialTermsIsCommercial()
        public
        withCommFramework(LicTestConfig({
            shareAlike: true,
            licConfig: TermsData.LicensorConfig.IpOrg,
            needsActivation: false
        }))
    {
        assertTrue(licensingModule.ipOrgAllowsCommercial(address(ipOrg)), "not commercial");
        assertTermsSetInIpOrg(true);// commercial terms
        assertTermsSetInIpOrg(false);// non commercial terms too
    }

    function test_LicensingModule_configIpOrg_revert_noEmptyNonCommercialTerms()
        public
    {
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(
            Errors.LicensingModule_NonCommercialTermsRequired.selector
        );
        spg.configureIpOrgLicensing(address(ipOrg), _getEmptyFramework());
        vm.stopPrank();
    }

    function test_LicensingModule_configIpOrg_revert_IfWrongTermCommercialStatus()
        public
    {
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(
            Errors.LicensingModule_InvalidTermCommercialStatus.selector
        );
        termIds[false].push(commTextTermId);
        termData[false].push(bytes(""));
        spg.configureIpOrgLicensing(
            address(ipOrg),
            _getFramework(false)
        );
        vm.stopPrank();
    }

    function test_LicensingModule_configIpOrg_revert_ipOrgAlreadySet()
        public
        withNonCommFramework(LicTestConfig({
            shareAlike: true,
            licConfig: TermsData.LicensorConfig.IpOrg,
            needsActivation: false
        })) {
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(
            Errors.LicensingModule_IpOrgFrameworkAlreadySet.selector
        );
        spg.configureIpOrgLicensing(
            address(ipOrg),
            _getFramework(false)
        );
        vm.stopPrank();
    }

    function test_LicensingModule_configIpOrg_protocolTermsMustBeSet()
        public
        withNonCommFramework(LicTestConfig({
            shareAlike: true,
            licConfig: TermsData.LicensorConfig.ParentLicensee,
            needsActivation: true
        })) {
            assertEq(licensingModule.isShareAlikeOn(false, address(ipOrg)), true);
            assertEq(
                uint8(licensingModule.getLicensorConfig(false, address(ipOrg))),
                uint8(TermsData.LicensorConfig.ParentLicensee)
            );
            assertEq(licensingModule.isLicensorAppovalOn(false, address(ipOrg)), true);
    }

}
