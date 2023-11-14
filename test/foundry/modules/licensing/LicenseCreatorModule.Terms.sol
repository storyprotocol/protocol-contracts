// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "test/foundry/utils/BaseTest.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/lib/modules/LibRelationship.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { TermIds, TermCategories } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { BaseLicensingTest } from "./BaseLicensingTest.sol";
import { ProtocolTermsHelper } from "contracts/modules/licensing/ProtocolTermsHelper.sol";

contract LicensingCreatorModuleTermsTest is BaseLicensingTest {
    using ShortStrings for *;

    address licensee = address(0x22222);
    address ipaOwner2 = address(0x33333);

    function setUp() public override {
        super.setUp();
    }

    function test_LicensingModule_terms_shareAlikeOn()
        public
        withNonCommFrameworkShareAlike
        withRootLicense(false)
    {
        uint256 ipaId2 = registry.register(
            IPAsset.RegisterIpAssetParams({
                name: "derivative",
                ipAssetType: 2,
                owner: ipaOwner2,
                ipOrg: (address(ipOrg)),
                hash: keccak256("test2"),
                url: "https://example2.com",
                data: ""
            })
        );
        vm.prank(ipaOwner2);
        uint256 lId = spg.createLicense(
            address(ipOrg),
            Licensing.LicenseCreationParams({
                parentLicenseId: nonCommRootLicenseId,
                isCommercial: false,
                ipaId: ipaId2
            }),
            new bytes[](0),
            new bytes[](0)
        );
        Licensing.License memory license = licenseRegistry.getLicense(lId);
        assertTerms(license);
        vm.expectRevert();
        licenseRegistry.ownerOf(lId);
        assertLicenseRelatedWithIpa(lId, ipaId2, true);
        assertIsSublicenseOf(lId, nonCommRootLicenseId, true);
    }

    function test_LicensingModule_terms_revert_shareAlikeOff()
    public
    withNonCommFrameworkNoShareAlike
    withRootLicense(false) {

        // expect revert LicensingModule_ShareAlikeDisabled when creating sublicense
        vm.startPrank(ipaOwner2);
        vm.expectRevert(Errors.LicensingModule_ShareAlikeDisabled.selector);
        spg.createLicense(
            address(ipOrg),
            Licensing.LicenseCreationParams({
                parentLicenseId: nonCommRootLicenseId,
                isCommercial: false,
                ipaId: 1
            }),
            new bytes[](0),
            new bytes[](0)
        );
        vm.stopPrank();
        // have licensor create a license
        console.log("nonCommRootLicenseId", nonCommRootLicenseId);
        
        vm.prank(ipaOwner);
        uint256 lId = spg.createLicense(
            address(ipOrg),
            Licensing.LicenseCreationParams({
                parentLicenseId: nonCommRootLicenseId,
                isCommercial: false,
                ipaId: 0
            }),
            new bytes[](0),
            new bytes[](0)
        );
        Licensing.License memory license = licenseRegistry.getLicense(lId);
        console.log("lId", lId);
        console.log("licenseeType", uint8(license.licenseeType));
        // Non Commercial
        assertEq(licenseRegistry.ownerOf(lId), ipaOwner);
        assertEq(licenseRegistry.getLicensee(lId), ipaOwner);
        // transfer license to other guy
        vm.prank(ipaOwner);
        licenseRegistry.transferFrom(ipaOwner, ipaOwner2, lId);
        // have other guy activate license
        
        // have other guy mint ipa, burn LNFT and tie it to IPA

    }

}
