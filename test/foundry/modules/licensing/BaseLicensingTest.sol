// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { ShortStrings, ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import 'test/foundry/utils/BaseTest.sol';
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { TermCategories, TermIds } from "contracts/lib/modules/ProtocolLicensingTerms.sol";

struct LicTestConfig {
    bool shareAlike;
    TermsData.LicensorConfig licConfig;
}
struct TestTermConfig {
    ShortString termId;
    bytes data;
}

contract BaseLicensingTest is BaseTest {
    using ShortStrings for *;

    ShortString public textTermId = "text_term_id".toShortString();
    ShortString public nonCommTextTermId = "non_comm_text_term_id".toShortString();
    ShortString public commTextTermId = "comm_text_term_id".toShortString();

    uint256 public rootIpaId;
    address public ipaOwner = address(0x13333);

    uint256 public commRootLicenseId;
    uint256 public nonCommRootLicenseId;

    ShortString[] public nonCommTermIds;
    bytes[] public nonCommTermData;
    ShortString[] public commTermIds;
    bytes[] public commTermData;

     

    modifier withNonCommFrameworkShareAlike() {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getNonCommFramework(true)
        );
        _;
    }

    modifier withNonCommFrameworkNoShareAlike() {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getNonCommFramework(false)
        );
        _;
    }

    modifier withNonCommFrameworkShareAlikeAnd(
        ShortString termId,
        bytes memory data
    ) {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getNonCommFrameworkAndPush(true, termId, data)
        );
        _;
    }

    modifier withNonCommFrameworkNoShareAlikeAnd(
        ShortString termId,
        bytes memory data
    ) {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getNonCommFrameworkAndPush(false, termId, data)
        );
        _;
    }

    modifier withCommFrameworkShareAlike() {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getCommFramework(true, true)
        );
        _;
    }

    modifier withCommFrameworkNoShareAlike() {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getCommFramework(false, false)
        );
        _;
    }

    modifier withCommFrameworkShareAlikeAnd(
        ShortString ncTermId,
        bytes memory ncData,
        ShortString cTermId,
        bytes memory cData
    ) {
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            getCommFrameworkAndPush(true, ncTermId, ncData, true, cTermId, cData)
        );
        _;
    }

    modifier withRootLicense(bool commercial) {
        vm.prank(ipOrg.owner());
        uint256 lId = spg.createIpaBoundLicense(
            address(ipOrg),
            Licensing.LicenseCreation({
                parentLicenseId: 0,
                isCommercial: commercial
            }),
            rootIpaId,
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
        _addProtocolTerms();
        _addTextTerms();
        nonCommTermIds = [textTermId, nonCommTextTermId];
        nonCommTermData = [bytes(""), bytes("")];
        commTermIds = [commTextTermId];
        commTermData = [bytes("")];
        rootIpaId = _createIpAsset(ipaOwner, 2, bytes(""));
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

    function getCommFramework(
        bool comShareAlike,
        TermsData.LicensorConfig comLicConfig,
        bool nonComShareAlike,
        TermsData.LicensorConfig nonComLicConfig
    ) public returns (Licensing.FrameworkConfig memory) {
        nonCommTermIds.push(TermIds.NFT_SHARE_ALIKE.toShortString());
        nonCommTermData.push(abi.encode(nonComShareAlike));
        nonCommTermIds.push(TermIds.LICENSOR_IPORG_OR_PARENT.toShortString());
        nonCommTermData.push(abi.encode(nonComShareAlike));
        commTermIds.push(TermIds.NFT_SHARE_ALIKE.toShortString());
        commTermData.push(abi.encode(comShareAlike));
        commTermIds.push(TermIds.LICENSOR_IPORG_OR_PARENT.toShortString());
        commTermData.push(abi.encode(comLicConfig));
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

    function getNonCommFramework(bool shareAlike, TermsData.LicensorConfig licConfig) public returns (Licensing.FrameworkConfig memory) {
        nonCommTermIds.push(TermIds.NFT_SHARE_ALIKE.toShortString());
        nonCommTermData.push(abi.encode(shareAlike));
        nonCommTermIds.push(TermIds.LICENSOR_IPORG_OR_PARENT.toShortString());
        nonCommTermData.push(abi.encode(licConfig));
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
        LicTestConfig comConf,
        TestTermConfig comTerm
    ) public returns (Licensing.FrameworkConfig memory) {
        nonCommTermIds.push(comTerm.termId);
        nonCommTermData.push(comTerm.data);
        return getNonCommFramework(comConf.shareAlike, comConf.licConfig);
    }

    function getCommFrameworkAndPush(
        LicTestConfig comConf,
        TestTermConfig comTerm,
        LicTestConfig nonComConf,
        TestTermConfig nonComTerm
    ) public returns (Licensing.FrameworkConfig memory) {
        nonCommTermIds.push(ncTermId);
        nonCommTermData.push(ncData);
        
        commTermIds.push(cTermId);
        commTermData.push(cData);

        return getCommFramework(com, ncShareAlike);
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

    function _addProtocolTerms() private {
        Licensing.CommercialStatus comStatus = Licensing.CommercialStatus.Both;
        licensingModule.addCategory(TermCategories.SHARE_ALIKE);
        Licensing.LicensingTerm memory term = _getTerm(TermIds.NFT_SHARE_ALIKE, comStatus);
        licensingModule.addTerm(TermCategories.SHARE_ALIKE, TermIds.NFT_SHARE_ALIKE, term);

        licensingModule.addCategory(TermCategories.LICENSOR);
        term = _getTerm(TermIds.LICENSOR_APPROVAL, comStatus);
        licensingModule.addTerm(TermCategories.LICENSOR, TermIds.LICENSOR_APPROVAL, term);

        licensingModule.addCategory(TermCategories.CATEGORIZATION);
        term = _getTerm(TermIds.FORMAT_CATEGORY, comStatus);
        licensingModule.addTerm(TermCategories.CATEGORIZATION, TermIds.FORMAT_CATEGORY, term);

        licensingModule.addCategory(TermCategories.ACTIVATION);
        term = _getTerm(TermIds.LICENSOR_IPORG_OR_PARENT, comStatus);
        licensingModule.addTerm(TermCategories.ACTIVATION, TermIds.LICENSOR_IPORG_OR_PARENT, term);
    }

    function _getTerm(
        string memory termId,
        Licensing.CommercialStatus comStatus_
    ) internal pure returns (Licensing.LicensingTerm memory) {
        return Licensing.LicensingTerm({
            comStatus: comStatus_,
            url: string(abi.encodePacked("https://", termId,".com")),
            hash: "qwertyu",
            algorithm: "sha256",
            hook: IHook(address(0))
        });
    }

    function _addTextTerms() private {
        licensingModule.addCategory("test_category");
        licensingModule.addTerm(
            "test_category",
            "text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Both,
                url: "https://text_term_id.com",
                hash: "qwertyu",
                algorithm: "sha256",
                hook: IHook(address(0))
            }
        ));
        licensingModule.addTerm(
            "test_category",
            "non_comm_text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.NonCommercial,
                url: "https://non_comm_text_term_id.com",
                hash: "qwertyu",
                algorithm: "sha256",
                hook: IHook(address(0))
            }
        ));
        licensingModule.addTerm(
            "test_category",
            "comm_text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Commercial,
                url: "https://comm_text_term_id.com",
                hash: "qwertyu",
                algorithm: "sha256",
                hook: IHook(address(0))
            }
        ));
    }

}
