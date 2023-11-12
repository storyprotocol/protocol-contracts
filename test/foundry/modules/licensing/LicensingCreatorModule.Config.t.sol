// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import 'contracts/modules/relationships/RelationshipModule.sol';
import 'contracts/lib/modules/LibRelationship.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing, TermCategories, TermIds } from "contracts/lib/modules/Licensing.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";

contract LicensingCreatorModuleConfigTest is BaseTest {
    using ShortStrings for *;

    ShortString public textTermId = "text_term_id".toShortString();

    function setUp() override public {
        super.setUp();
        licensingModule.addTermCategory("test_category");
        licensingModule.addTerm(
            "test_category",
            "text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Both,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                hook: IHook(address(0))
            }
        ));
    }

    function test_LicensingModule_configIpOrg_revertIfNotIpOrgOwner() public {
        vm.expectRevert(Errors.LicensingModule_CallerNotIpOrgOwner.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                comTermsConfig: new Licensing.TermsConfig[](0),
                nonComTermsConfig: new Licensing.TermsConfig[](1)
            })
        );
    }
    function test_LicensingModule_configIpOrg_ipOrgWithNoCommercialTermsIsNonCommercial() public {
        Licensing.TermsConfig[] memory nonComTerms = new Licensing.TermsConfig[](1);
        nonComTerms[0] = Licensing.TermsConfig({
            termId: textTermId,
            data: ""
        });

        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                comTermsConfig: new Licensing.TermsConfig[](0),
                nonComTermsConfig: nonComTerms
            })
        );
        assertFalse(licensingModule.ipOrgAllowsCommercial(address(ipOrg)));
        (bytes32[] memory nonComTermIds, bytes[] memory nonComTermData) = licensingModule.getIpOrgTerms(false, address(ipOrg));
        assertTrue(ShortStringOps._equal(nonComTermIds[0], textTermId));
        (bytes32[] memory termIds, bytes[] memory termsData) = licensingModule.getIpOrgTerms(true, address(ipOrg));
        assertTrue(termIds.length == 0);
    }

    function test_LicensingModule_configIpOrg_ipOrgWithCommercialTermsIsCommercial() public {
        Licensing.TermsConfig[] memory nonComTerms = new Licensing.TermsConfig[](1);
        nonComTerms[0] = Licensing.TermsConfig({
            termId: textTermId,
            data: ""
        });
        Licensing.TermsConfig[] memory comTerms = nonComTerms;
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                comTermsConfig: comTerms,
                nonComTermsConfig: nonComTerms
            })
        );
        assertTrue(licensingModule.ipOrgAllowsCommercial(address(ipOrg)));
        (bytes32[] memory nonComTermIds, bytes[] memory nonComTermData) = licensingModule.getIpOrgTerms(false, address(ipOrg));
        assertTrue(ShortStringOps._equal(nonComTermIds[0], textTermId));
        (bytes32[] memory termIds, bytes[] memory termsData) = licensingModule.getIpOrgTerms(true, address(ipOrg));
        assertTrue(ShortStringOps._equal(termIds[0], textTermId));
    }

    function test_LicensingModule_configIpOrg_revert_noEmptyNonCommercialTerms() public {
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(Errors.LicensingModule_NonCommercialTermsRequired.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                comTermsConfig: new Licensing.TermsConfig[](0),
                nonComTermsConfig: new Licensing.TermsConfig[](0)
            })
        );
        vm.stopPrank();
    }

    function test_LicensingModule_configIpOrg_revertIfWrongTermCommercialStatus() public {
        licensingModule.addTerm(
            "test_category",
            "term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Commercial,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                hook: IHook(address(0))
            }
        ));
        ShortString termId = "term_id".toShortString();
        Licensing.TermsConfig[] memory nonComTerms = new Licensing.TermsConfig[](1);
        nonComTerms[0] = Licensing.TermsConfig({
            termId: textTermId,
            data: ""
        });
        Licensing.TermsConfig[] memory comTerms = nonComTerms;
        vm.startPrank(ipOrg.owner());
        vm.expectRevert(Errors.LicensingModule_InvalidTermCommercialStatus.selector);
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                comTermsConfig: comTerms,
                nonComTermsConfig: nonComTerms
            })
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

