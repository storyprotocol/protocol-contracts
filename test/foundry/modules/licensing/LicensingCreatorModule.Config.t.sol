// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'contracts/modules/relationships/RelationshipModule.sol';
import 'contracts/lib/modules/LibRelationship.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing, TermCategories, TermIds } from "contracts/lib/modules/Licensing.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { BaseLicensingTest } from "./BaseLicensingTest.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract LicensingCreatorModuleConfigTest is BaseLicensingTest {

    function setUp() override public {
        super.setUp();
    }

    function test_LicensingModule_configIpOrg_revertIfNotIpOrgOwner() public {
        vm.expectRevert(Errors.LicensingModule_CallerNotIpOrgOwner.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getNonCommLicensingFramework(
                textTermId,
                bytes("")
            )
        );
    }
    function test_LicensingModule_configIpOrg_ipOrgWithNoCommercialTermsIsNonCommercial() public {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getNonCommLicensingFramework(
                textTermId,
                bytes("")
            )
        );
        assertFalse(licensingModule.ipOrgAllowsCommercial(address(ipOrg)));
        (ShortString[] memory nonComTermIds, bytes[] memory nonComTermData) = licensingModule.getIpOrgTerms(false, address(ipOrg));
        assertTrue(ShortStringOps._equal(nonComTermIds[0], textTermId));
        (ShortString[] memory termIds, bytes[] memory termsData) = licensingModule.getIpOrgTerms(true, address(ipOrg));
        assertTrue(termIds.length == 0);
    }

    function test_LicensingModule_configIpOrg_ipOrgWithCommercialTermsIsCommercial() public {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getCommLicensingFramework(
                textTermId,
                bytes("")
            )
        );
        assertTrue(licensingModule.ipOrgAllowsCommercial(address(ipOrg)));
        (ShortString[] memory nonComTermIds, bytes[] memory nonComTermData) = licensingModule.getIpOrgTerms(false, address(ipOrg));
        assertTrue(ShortStringOps._equal(nonComTermIds[0], textTermId));
        (ShortString[] memory termIds, bytes[] memory termsData) = licensingModule.getIpOrgTerms(true, address(ipOrg));
        assertTrue(ShortStringOps._equal(termIds[0], textTermId));
    }

    function test_LicensingModule_configIpOrg_revert_noEmptyNonCommercialTerms() public {
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(Errors.LicensingModule_NonCommercialTermsRequired.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getEmptyLicensingFramework()
        );
        vm.stopPrank();
    }

    function test_LicensingModule_configIpOrg_revertIfWrongTermCommercialStatus() public {
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(Errors.LicensingModule_InvalidTermCommercialStatus.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getCommLicensingFramework(
                nonCommTextTermId,
                bytes("")
            )
        );
        vm.stopPrank();
    }

    function test_LicensingModule_configIpOrg_revertIfIpOrgAlreadyConfigured() public {
        // Todo
    }


    function test_LicensingModule_configIpOrg_setsHooksForCreatingCommercialLicenses() public {
        // Todo
    }
    
    function test_LicensingModule_configIpOrg_setsHooksForCreatingNonCommercialLicenses() public {
        // Todo
    }

    function test_LicensingModule_configIpOrg_commercialLicenseActivationHooksCanBeSet() public {
        // TODO
    }

    function test_LicensingModule_configIpOrg_nonCommercialLicenseActivationHooksCanBeSet() public {
        // TODO
    }


    function test_LicensingModule_licensing_createsCommercialLicense() public {

    }

    
    function test_LicensingModule_licensing_createsNonCommercialLicense() public {
        
    }    
}

