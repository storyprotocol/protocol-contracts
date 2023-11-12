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

/// Test for particular terms
contract LicensingCreatorModuleTermsTest is BaseTest {
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
    

    function test_LicensingModule_configIpOrg_availableCategoriesCanBeSet() public {

    }

    function test_LicensingModule_licensing_revert_categoryExcluded() public {
       // TODO that term
    }


    function test_LicensingModule_licensing_shouldAskForLicensor() public {

    }

    function test_LicensingModule_licensing_licensorPreviousLicenseHolder() public {

    }

}

