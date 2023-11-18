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
    bool needsActivation;
}

struct AddTermConfig {
    ShortString termId;
    bytes data;
}

contract BaseLicensingTest is BaseTest {
    using ShortStrings for *;

    ShortString public textTermId = "text_term_id".toShortString();
    ShortString public nonCommTextTermId = "non_comm_text_term_id".toShortString();
    ShortString public commTextTermId = "comm_text_term_id".toShortString();

    address public ipaOwner = address(0x13333);

    mapping(bool => ShortString[]) public termIds;
    mapping(bool => bytes[]) public termData;

    modifier withNonCommFramework(LicTestConfig memory config) {
        _addTerms(false, config);
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            _getFramework(false)
        );
        _;
    }

    modifier withCommFramework(LicTestConfig memory config) {
        _addTerms(false, config);
        _addTerms(true, config);
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            _getFramework(true)
        );
        _;
    }


    function setUp() virtual override public {
        super.setUp();
        _addProtocolTerms();
        _addTextTerms();
        termIds[true].push(textTermId);
        termIds[true].push(commTextTermId);
        termData[true].push(bytes(""));
        termData[true].push(bytes(""));

        termIds[false].push(textTermId);
        termIds[false].push(nonCommTextTermId);
        termData[false].push(bytes(""));
        termData[false].push(bytes(""));
    }

    function _addTerms(bool commercial, LicTestConfig memory config) internal {
        termIds[commercial].push(TermIds.NFT_SHARE_ALIKE.toShortString());
        termData[commercial].push(abi.encode(config.shareAlike));
        termIds[commercial].push(TermIds.LICENSOR_APPROVAL.toShortString());
        termData[commercial].push(abi.encode(config.needsActivation));
        termIds[commercial].push(TermIds.LICENSOR_IPORG_OR_PARENT.toShortString());
        termData[commercial].push(abi.encode(config.licConfig));
    }

    function _getFramework(bool commercial) internal view returns (Licensing.FrameworkConfig memory) {
        if (commercial) {
            return Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: termIds[commercial],
                    termData: termData[commercial]
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: termIds[!commercial],
                    termData: termData[!commercial]
                })
            });
        } else {
            return Licensing.FrameworkConfig({
                comTermsConfig: Licensing.TermsConfig({
                    termIds: new ShortString[](0),
                    termData: new bytes[](0)
                }),
                nonComTermsConfig: Licensing.TermsConfig({
                    termIds: termIds[commercial],
                    termData: termData[commercial]
                })
            });
        }
    }
    
    function _getEmptyFramework() internal pure returns (Licensing.FrameworkConfig memory) {
        return Licensing.FrameworkConfig({
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

    function _addProtocolTerms() private {
        Licensing.CommercialStatus comStatus = Licensing.CommercialStatus.Both;
        vm.startPrank(termSetter);
        termsRepository.addCategory(TermCategories.SHARE_ALIKE);
        Licensing.LicensingTerm memory term = _getTerm(TermIds.NFT_SHARE_ALIKE, comStatus);
        termsRepository.addTerm(TermCategories.SHARE_ALIKE, TermIds.NFT_SHARE_ALIKE, term);

        termsRepository.addCategory(TermCategories.LICENSOR);
        term = _getTerm(TermIds.LICENSOR_APPROVAL, comStatus);
        termsRepository.addTerm(TermCategories.LICENSOR, TermIds.LICENSOR_APPROVAL, term);

        termsRepository.addCategory(TermCategories.CATEGORIZATION);
        term = _getTerm(TermIds.FORMAT_CATEGORY, comStatus);
        termsRepository.addTerm(TermCategories.CATEGORIZATION, TermIds.FORMAT_CATEGORY, term);

        termsRepository.addCategory(TermCategories.ACTIVATION);
        term = _getTerm(TermIds.LICENSOR_IPORG_OR_PARENT, comStatus);
        termsRepository.addTerm(TermCategories.ACTIVATION, TermIds.LICENSOR_IPORG_OR_PARENT, term);
        vm.stopPrank();
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
        vm.startPrank(termSetter);
        termsRepository.addCategory("test_category");
        termsRepository.addTerm(
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
        termsRepository.addTerm(
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
        termsRepository.addTerm(
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
        vm.stopPrank();
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
            Licensing.LicensingTerm memory term = termsRepository.getTerm(ipOrgTermsId[i]);
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
        ShortString[] memory tIds = termIds[commercial];
        bytes[] memory tData = termData[commercial];
        assertEq(tIds.length, ipOrgTermsId.length);
        assertEq(tData.length, ipOrgTermsData.length);
        uint256 length = termIds[commercial].length;
        for (uint256 i = 0; i < length; i++) {
            assertTrue(ShortStringOps._equal(tIds[i], ipOrgTermsId[i]));
            assertTrue(keccak256(tData[i]) == keccak256(ipOrgTermsData[i]));
        }
    }
}
