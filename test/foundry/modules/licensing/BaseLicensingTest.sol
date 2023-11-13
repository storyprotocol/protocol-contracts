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

    uint256 public commRootLicenseId;
    uint256 public nonCommRootLicenseId;

    ShortString[] public nonCommTermIds;
    bytes[] public nonCommTermData;
    ShortString[] public commTermIds;
    bytes[] public commTermData;

    modifier withNonCommFramework() {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getNonCommFramework()
        );
        _;
    }

    modifier withCommFramework() {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getCommFramework()
        );
        _;
    }

    modifier withRootLicense(bool commercial) {
        vm.prank(ipOrg.owner());
        uint256 lId = spg.createLicense(
            address(ipOrg),
            Licensing.LicenseCreationParams({
                parentLicenseId: 0,
                isCommercial: commercial,
                ipaId: 1
            }),
            new bytes[](0),
            new bytes[](0)
        );
        if (commercial) {
            commRootLicenseId = lId;
        } else {
            nonCommRootLicenseId = lId;
        }
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
        nonCommTermIds = [
            textTermId,
            nonCommTextTermId
        ];
        nonCommTermData = [
            bytes(""),
            bytes("")
        ];
        commTermIds = [
            // textTermId,
            commTextTermId
        ];
        commTermData = [
            // bytes(""),
            bytes("")
        ];
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

    function getCommFramework() public view returns (Licensing.FrameworkConfig memory) {
        return
            Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: commTermIds,
                    termData: commTermData
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: nonCommTermIds,
                    termData: nonCommTermData
                })
            });
    }

    function getNonCommFramework() public view returns (Licensing.FrameworkConfig memory) {
        return
            Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: new ShortString[](0),
                    termData: new bytes[](0)
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: nonCommTermIds,
                    termData: nonCommTermData
                })
            });
    }

    function getNonCommFrameworkAndPush(
        ShortString termId,
        bytes memory data
    ) public returns (Licensing.FrameworkConfig memory) {
        nonCommTermIds.push(termId);
        nonCommTermData.push(data);
        return getNonCommFramework();
    }

    function getCommFrameworkAndPush(
        ShortString ncTermId,
        bytes memory ncData,
        ShortString cTermId,
        bytes memory cData
    ) public returns (Licensing.FrameworkConfig memory) {
        if (!ShortStringOps._equal(ncTermId, "".toShortString())) {
            commTermIds.push(ncTermId);
            commTermData.push(ncData);
        }
        if (!ShortStringOps._equal(cTermId, "".toShortString())) {
            commTermIds.push(cTermId);
            commTermData.push(cData);
        }
        return getCommFramework();
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

    function assertTermsSetInIpOrg(bool commercial) public {
        (ShortString[] memory ipOrgTermsId, bytes[] memory ipOrgTermsData) = licensingModule.getIpOrgTerms(
            commercial, address(ipOrg)
        );
        ShortString[] memory termIds = commercial ? commTermIds : nonCommTermIds;
        bytes[] memory termData = commercial ? commTermData : nonCommTermData;
        assertEq(termIds.length, ipOrgTermsId.length);
        assertEq(termData.length, ipOrgTermsData.length);
        for (uint256 i = 0; i < termIds.length; i++) {
            assertTrue(ShortStringOps._equal(termIds[i], ipOrgTermsId[i]));
            assertTrue(keccak256(termData[i]) == keccak256(ipOrgTermsData[i]));
        }
    }

}
