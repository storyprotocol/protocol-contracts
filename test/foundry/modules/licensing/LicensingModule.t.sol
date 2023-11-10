// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import 'contracts/modules/relationships/RelationshipModule.sol';
import 'contracts/lib/modules/LibRelationship.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing, TermCategories, TermIds } from "contracts/lib/modules/Licensing.sol";
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
                termIds: new string[](0),
                termConfigs: new bytes[](0),
                ipCategories: new string[](0)
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
                termIds: new string[](0),
                termConfigs: new bytes[](0),
                ipCategories: new string[](0)
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
                hook: address(0)
            }
        ));
        string[] memory termIds = new string[](1);
        termIds[0] = "term_id";
        bytes[] memory termConfigs = new bytes[](1);
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                isCommercialAllowed: true,
                termIds: termIds,
                termConfigs: termConfigs,
                ipCategories: new string[](0)
            })
        );
        Licensing.FrameworkConfig memory framework = licensingModule.getFramework(address(ipOrg));
        assertEq(framework.termIds[0], "term_id");
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
                hook: address(0)
            }
        ));
        string[] memory termIds = new string[](1);
        termIds[0] = "term_id";
        bytes[] memory termConfigs = new bytes[](1);
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(Errors.LicensingModule_CommercialTermNotAllowed.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                isCommercialAllowed: false,
                termIds: termIds,
                termConfigs: termConfigs,
                ipCategories: new string[](0)
            })
        );
        vm.stopPrank();
    }
    

    function test_LicensingModule_configIpOrg_availableCategoriesCanBeSet() public {
        
        string[] memory categories = new string[](2);
        categories[0] = "movies";
        categories[1] = "music";
        
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                isCommercialAllowed: true,
                termIds: new string[](0),
                termConfigs: new bytes[](0),
                ipCategories: categories
            })
        );
        Licensing.FrameworkConfig memory framework = licensingModule.getFramework(address(ipOrg));
        assertEq(framework.ipCategories[0], "movies");
        assertEq(framework.ipCategories[1], "music");
        assertEq(framework.ipCategories.length, 2);
    }

    function test_LicensingModule_licensing_revert_categoryExcluded() public {
        // TODO: just check that new category is included
        // Licensing.LicensingTerm memory term = licensingModule.getExcludedCategoriesTerm(
        //     Licensing.CommercialStatus.Both,
        //     address(0),
        //     new string[](0)
        // );

        // licensingModule.addTerm(
        //     TermCategories.FORMAT_CATEGORIES,
        //     TermIds.
        //     term
        // );
        // string[] memory categories = new string[]()
        // string[] memory termIds = new string[](1);
        // termIds[0] = TermCategories.TermIds;
        // bytes[] memory termConfigs = new bytes[](1);
        // vm.startPrank(ipOrg.owner());
        // vm.expectRevert(Errors.LicensingModule_CommercialTermNotAllowed.selector);
        // spg.configureIpOrgLicensing(
        //     address(ipOrg),
        //     Licensing.FrameworkConfig({
        //         isCommercialAllowed: false,
        //         termIds: termIds,
        //         termConfigs: termConfigs,
        //         ipCategories: new string[](0)
        //     })
        // );
        // vm.stopPrank();
    }

    function test_LicensingModule_configIpOrg_commercialLicenseActivationHooksCanBeSet() public {
        // TODO
    }

    function test_LicensingModule_configIpOrg_nonCommercialLicenseActivationHooksCanBeSet() public {
        // TODO
    }

    function test_LicensingModule_licensing_shouldAskForLicensor() public {

    }

    function test_LicensingModule_licensing_licensorPreviousLicenseHolder() public {

    }

    function test_LicensingModule_configIpOrg_setsHooksForCreatingCommercialLicenses() public {
        // Todo
    }
    
    function test_LicensingModule_configIpOrg_setsHooksForCreatingNonCommercialLicenses() public {
        // Todo
    }


    function test_LicensingModule_licensing_createsCommercialLicense() public {

    }

    
    function test_LicensingModule_licensing_createsNonCommercialLicense() public {
        
    }    
}

