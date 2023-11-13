// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { ShortStrings, ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import 'test/foundry/utils/BaseTest.sol';
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { OffChain } from "contracts/lib/OffChain.sol";

contract BaseLicensingTest is BaseTest {
    using ShortStrings for *;

    ShortString public textTermId = "text_term_id".toShortString();
    ShortString public nonCommTextTermId = "non_comm_text_term_id".toShortString();
    ShortString public commTextTermId = "comm_text_term_id".toShortString();

    modifier withNonCommFramework() {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getNonCommFramework(
                nonCommTextTermId,
                bytes("")
            )
        );
        _;
    }

    modifier withCommFramework() {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getCommFramework(
                commTextTermId,
                bytes(""),
                nonCommTextTermId,
                bytes("")
            )
        );
        _;
    }

    function setUp() virtual override public {
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
        licensingModule.addTerm(
            "test_category",
            "non_comm_text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.NonCommercial,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                hook: IHook(address(0))
            }
        ));
        licensingModule.addTerm(
            "test_category",
            "comm_text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Commercial,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                hook: IHook(address(0))
            }
        ));
    }

    function getEmptyFramework() public pure returns (Licensing.FrameworkConfig memory) {
        return
            Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: new ShortString[](0),
                    termData: new bytes[](0)
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: new ShortString[](0),
                    termData: new bytes[](0)
                })
            });
    }

    function getNonCommFramework(
        ShortString termId,
        bytes memory data
    ) public pure returns (Licensing.FrameworkConfig memory) {
        ShortString[] memory termIds = new ShortString[](1);
        termIds[0] = termId;
        bytes[] memory termData = new bytes[](1);
        termData[0] = data;
        return
            Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: new ShortString[](0),
                    termData: new bytes[](0)
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: termIds,
                    termData: termData
                })
            });
    }

    function getCommFramework(
        ShortString cId,
        bytes memory cData,
        ShortString ncId,
        bytes memory ncData
    ) public pure returns (Licensing.FrameworkConfig memory) {
        ShortString[] memory comTermsId = new ShortString[](1);
        comTermsId[0] = cId;
        bytes[] memory comTermsData = new bytes[](1);
        comTermsData[0] = cData;
        ShortString[] memory nonComTermsId = new ShortString[](1);
        nonComTermsId[0] = ncId;
        bytes[] memory nonComTermsData = new bytes[](1);
        nonComTermsData[0] = ncData;
        return
            Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: comTermsId,
                    termData: comTermsData
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: nonComTermsId,
                    termData: nonComTermsData
                })
            });
    }


    function assertTerms(Licensing.License memory license) public {
        (ShortString[] memory ipOrgTermsId, bytes[] memory ipOrgTermsData) = licensingModule.getIpOrgTerms(
            license.isCommercial, address(ipOrg)
        );
        assertEq(license.termIds.length, ipOrgTermsId.length);
        assertEq(license.termsData.length, ipOrgTermsData.length);
        for (uint256 i = 0; i < license.termIds.length; i++) {
            assertTrue(ShortStringOps._equal(license.termIds[i], ipOrgTermsId[i]));
            assertTrue(keccak256(license.termsData[i]) == keccak256(ipOrgTermsData[i]));
            Licensing.LicensingTerm memory term = licensingModule.getTerm(ipOrgTermsId[i]);
            if (license.isCommercial) {
                assertTrue(
                    term.comStatus == Licensing.CommercialStatus.Commercial ||
                    term.comStatus == Licensing.CommercialStatus.Both
                );
            } else {
                assertTrue(
                    term.comStatus == Licensing.CommercialStatus.NonCommercial ||
                    term.comStatus == Licensing.CommercialStatus.Both
                );
            }
        }
    }

}
