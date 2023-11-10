// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import 'contracts/modules/relationships/RelationshipModule.sol';
import 'contracts/lib/modules/LibRelationship.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract LicensingModuleTest is BaseTest {

    using ShortStrings for *;

    function setUp() override public {
        super.setUp();
        licensingModule.addTermCategory("test");
    }

    function test_LicensingModule_configIpOrg_shouldEnableCommercialLicenses() public {
        // TODO test event
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                isCommercialAllowed: true,
                termIds: new ShortString[](0),
                termConfigs: new bytes[](0)
            })
        );
        assertTrue(licensingModule.getFramework(address(ipOrg)).isCommercialAllowed);
    }

    function test_LicensingModule_configIpOrg_revertIfNotIpOrgOwner() public {
        vm.expectRevert(Errors.LicensingModule_CallerNotIpOrgOwner.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                isCommercialAllowed: true,
                termIds: new ShortString[](0),
                termConfigs: new bytes[](0)
            })
        );
    }

    function test_LicensingModule_configIpOrg_revertIfIpOrgAlreadyConfigured() public {
        // Todo
    }

    function test_LicensingModule_configIpOrg_textTermsCanBeSet() public {
        licensingModule.addTerm(
            "test_category",
            "term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Both,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                encoder: address(0)
            }
        ));
        ShortString termId = "term_id".toShortString();
        ShortString[] memory termIds = new ShortString[](1);
        termIds[0] = termId;
        bytes[] memory termConfigs = new bytes[](1);
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                isCommercialAllowed: true,
                termIds: termIds,
                termConfigs: termConfigs
            })
        );
        Licensing.FrameworkConfig memory term = licensingModule.getFramework(address(ipOrg));
        assertEq(ShortString.unwrap(term.termIds[0]), ShortString.unwrap(termId));
    }

    function test_LicensingModule_configIpOrg_revertIfWrongTermCommercialStatus() public {
        licensingModule.addTerm(
            "test_category",
            "term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.NonCommercial,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                encoder: address(0)
            }
        ));
        ShortString termId = "term_id".toShortString();
        ShortString[] memory termIds = new ShortString[](1);
        termIds[0] = termId;
        bytes[] memory termConfigs = new bytes[](1);
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(Errors.LicensingModule_CommercialTermNotAllowed.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                isCommercialAllowed: false,
                termIds: termIds,
                termConfigs: termConfigs
            })
        );
        vm.stopPrank();
    }
    

    function test_LicensingModule_configIpOrg_availableCategoriesCanBeSet() public {
        licensingModule.addTerm(
            "test_category",
            "term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Both,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                encoder: address(0)
            }
        ));
        ShortString termId = "term_id".toShortString();
        ShortString[] memory termIds = new ShortString[](1);
        termIds[0] = termId;
        bytes[] memory termConfigs = new bytes[](1);
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                isCommercialAllowed: true,
                termIds: termIds,
                termConfigs: termConfigs
            })
        );
        Licensing.FrameworkConfig memory term = licensingModule.getFramework(address(ipOrg));
        assertEq(ShortString.unwrap(term.termIds[0]), ShortString.unwrap(termId));
    }

    function test_LicensingModule_configIpOrg_termsToExcludeLicensingToCategoriesCanBeSet() public {


    }

    function test_LicensingModule_configIpOrg_commercialLicenseActivationHooksCanBeSet() public {
        //...
    }

    function test_LicensingModule_configIpOrg_nonCommercialLicenseActivationHooksCanBeSet() public {

    }


    function test_LicensingModule_configIpOrg_commercialLimitParamsCanBeSet() public {

    }

    function test_LicensingModule_configIpOrg_nonCommercialLimitParamsCanBeSet() public {

    }


    function test_LicensingModule_licensing_categoryOfIpOrgEntryCanBeSet() public {

    }

    function test_LicensingModule_licensing_shouldAskForLicensor() public {

    }

    function test_LicensingModule_licensing_licensorPreviousLicenseHolder() public {

    }

    function test_LicensingModule_configIpOrg_setsHooksForCreatingCommercialLicenses() public {
        // Todo
    }

    function test_LicensingModule_licensing_createsCommercialLicense() public {

    }

    function test_LicensingModule_configIpOrg_setsHooksForCreatingNonCommercialLicenses() public {
        // Todo
    }

    function test_LicensingModule_licensing_createsNonCommercialLicense() public {
        
    }    
}

