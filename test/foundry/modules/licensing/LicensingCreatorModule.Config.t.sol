// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/lib/modules/LibRelationship.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { TermCategories, TermIds } from "contracts/lib/modules/LicensingTerms.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { BaseLicensingTest } from "./BaseLicensingTest.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract LicensingCreatorModuleConfigTest is BaseLicensingTest {
    function setUp() public override {
        super.setUp();
    }

    function test_LicensingModule_configIpOrg_revertIfNotIpOrgOwner() public {
        vm.expectRevert(Errors.LicensingModule_CallerNotIpOrgOwner.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getNonCommFramework(textTermId, bytes(""))
        );
    }

    function test_LicensingModule_configIpOrg_ipOrgWithNoCommercialTermsIsNonCommercial()
        public
        withNonCommFramework
    {
        assertFalse(licensingModule.ipOrgAllowsCommercial(address(ipOrg)));
        (
            ShortString[] memory nonComTermIds,
            bytes[] memory nonComTermData
        ) = licensingModule.getIpOrgTerms(false, address(ipOrg));
        assertTrue(ShortStringOps._equal(nonComTermIds[0], nonCommTextTermId));
        (
            ShortString[] memory termIds,
            bytes[] memory termsData
        ) = licensingModule.getIpOrgTerms(true, address(ipOrg));
        assertTrue(termIds.length == 0);
    }

    function test_LicensingModule_configIpOrg_ipOrgWithCommercialTermsIsCommercial()
        public
        withCommFramework
    {
        assertTrue(licensingModule.ipOrgAllowsCommercial(address(ipOrg)));
        (
            ShortString[] memory nonComTermIds,
            bytes[] memory nonComTermData
        ) = licensingModule.getIpOrgTerms(false, address(ipOrg));
        assertTrue(ShortStringOps._equal(nonComTermIds[0], nonCommTextTermId));
        (
            ShortString[] memory termIds,
            bytes[] memory termsData
        ) = licensingModule.getIpOrgTerms(true, address(ipOrg));
        assertTrue(ShortStringOps._equal(termIds[0], commTextTermId));
    }

    function test_LicensingModule_configIpOrg_revert_noEmptyNonCommercialTerms()
        public
    {
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(
            Errors.LicensingModule_NonCommercialTermsRequired.selector
        );
        spg.configureIpOrgLicensing(address(ipOrg), getEmptyFramework());
        vm.stopPrank();
    }

    function test_LicensingModule_configIpOrg_revert_IfWrongTermCommercialStatus()
        public
    {
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(
            Errors.LicensingModule_InvalidTermCommercialStatus.selector
        );
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getCommFramework(
                nonCommTextTermId,
                bytes(""),
                nonCommTextTermId,
                bytes("")
            )
        );
        vm.stopPrank();
    }

    function test_LicensingModule_configIpOrg_revertIfIpOrgAlreadyConfigured()
        public
    {
        // Todo
    }

    function test_LicensingModule_configIpOrg_setsHooksForCreatingCommercialLicenses()
        public
    {
        // Todo
    }

    function test_LicensingModule_configIpOrg_setsHooksForCreatingNonCommercialLicenses()
        public
    {
        // Todo
    }

    function test_LicensingModule_configIpOrg_commercialLicenseActivationHooksCanBeSet()
        public
    {
        // TODO
    }

    function test_LicensingModule_configIpOrg_nonCommercialLicenseActivationHooksCanBeSet()
        public
    {
        // TODO
    }
}
