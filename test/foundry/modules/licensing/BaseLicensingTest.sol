// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { ShortStrings, ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import 'test/foundry/utils/BaseTest.sol';
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { TermCategories, TermIds } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
import { ProtocolTermsHelper } from "contracts/modules/licensing/ProtocolTermsHelper.sol";

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
        uint256 lId = spg.createLicense(
            address(ipOrg),
            Licensing.LicenseCreationParams({
                parentLicenseId: 0,
                isCommercial: commercial,
                ipaId: rootIpaId
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
        _addShareAlike(Licensing.CommercialStatus.Both);
        _addTextTerms();
        nonCommTermIds = [textTermId, nonCommTextTermId];
        nonCommTermData = [bytes(""), bytes("")];
        commTermIds = [commTextTermId];
        commTermData = [bytes("")];
        rootIpaId = registry.register(
            IPAsset.RegisterIpAssetParams({
                name: "test",
                ipAssetType: 2,
                owner: ipaOwner,
                ipOrg: (address(ipOrg)),
                hash: keccak256("test"),
                url: "https://example.com",
                data: ""
            })
        );
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

    function getCommFramework(bool comShareAlike, bool nonComShareAlike) public returns (Licensing.FrameworkConfig memory) {
        commTermIds.push(TermIds.NFT_SHARE_ALIKE.toShortString());
        commTermData.push(abi.encode(comShareAlike));
        nonCommTermIds.push(TermIds.NFT_SHARE_ALIKE.toShortString());
        nonCommTermData.push(abi.encode(nonComShareAlike));
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

    function getNonCommFramework(bool shareAlike) public returns (Licensing.FrameworkConfig memory) {
        nonCommTermIds.push(TermIds.NFT_SHARE_ALIKE.toShortString());
        nonCommTermData.push(abi.encode(shareAlike));
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
        bool shareAlike,
        ShortString termId,
        bytes memory data
    ) public returns (Licensing.FrameworkConfig memory) {
        nonCommTermIds.push(termId);
        nonCommTermData.push(data);
        return getNonCommFramework(shareAlike);
    }

    function getCommFrameworkAndPush(
        bool cShareAlike,
        ShortString ncTermId,
        bytes memory ncData,
        bool ncShareAlike,
        ShortString cTermId,
        bytes memory cData
    ) public returns (Licensing.FrameworkConfig memory) {
        nonCommTermIds.push(ncTermId);
        nonCommTermData.push(ncData);
        
        commTermIds.push(cTermId);
        commTermData.push(cData);

        return getCommFramework(cShareAlike, ncShareAlike);
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

    function assertLicenseRelatedWithIpa(uint256 lId, uint256 ipaId, bool result) public {
        assertEq(
            relationshipModule.relationshipExists(
                LibRelationship.Relationship({
                    relType: ProtocolRelationships.IPA_LICENSE,
                    srcAddress: address(licenseRegistry),
                    srcId: lId,
                    dstAddress: address(registry),
                    dstId: ipaId
                })
            ),
            result
        );
    }

    function assertIsSublicenseOf(uint256 lId, uint256 parentLicenseId, bool result) public {
        assertEq(
            relationshipModule.relationshipExists(
                LibRelationship.Relationship({
                    relType: ProtocolRelationships.SUBLICENSE_OF,
                    srcAddress: address(licenseRegistry),
                    srcId: lId,
                    dstAddress: address(licenseRegistry),
                    dstId: parentLicenseId
                })
            ),
            result
        );
    }

    function _addShareAlike(Licensing.CommercialStatus comStatus) private {
        licensingModule.addCategory(TermCategories.SHARE_ALIKE);
        Licensing.LicensingTerm memory term = ProtocolTermsHelper._getNftShareAlikeTerm(comStatus);
        licensingModule.addTerm(
            TermCategories.SHARE_ALIKE,
            TermIds.NFT_SHARE_ALIKE,
            term
        );
    }

    function _addTextTerms() private {
        licensingModule.addCategory("test_category");
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

}
