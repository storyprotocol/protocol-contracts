// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "test/foundry/utils/BaseTest.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/lib/modules/LibRelationship.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { TermCategories, TermIds } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { BaseLicensingTest } from "./BaseLicensingTest.sol";

contract LicensingCreatorLicensingTest is BaseLicensingTest {
    using ShortStrings for *;

    address lnftOwner = address(0x13334);

    function setUp() public override {
        super.setUp();
        
    }

    function test_LicensingModule_configIpOrg_commercialLicenseActivationHooksCanBeSet()
        public
    {
        // TODO
    }

    function test_LicensingModule_configIpOrg_nonCommercialLicenseActivationHooksCanBeSet()
        public
    {
        // TODO
    }

    function test_LicensingModule_licensing_createNonCommercialRootLicense()
        public
        withNonCommFrameworkShareAlike
    {
        vm.prank(ipOrg.owner());
        uint256 lId = spg.createLicense(
            address(ipOrg),
            Licensing.LicenseCreationParams({
                parentLicenseId: 0,
                isCommercial: false,
                ipaId: rootIpaId
            }),
            new bytes[](0),
            new bytes[](0)
        );
        // Non Commercial
        Licensing.License memory license = licenseRegistry.getLicense(lId);
        assertFalse(license.isCommercial);
        assertEq(license.revoker, ipOrg.owner());
        assertEq(license.licensor, ipaOwner, "licensor");

        assertTerms(license);
        assertLicenseRelatedWithIpa(lId, rootIpaId, true);
    }

    function test_LicensingModule_licensing_createsCommercialSubLicense_noDestIpa()
        public
        withCommFrameworkShareAlike
        withRootLicense(false)
        withRootLicense(true)
    {
        vm.prank(lnftOwner);
        uint256 lId = spg.createLicense(
            address(ipOrg),
            Licensing.LicenseCreationParams({
                parentLicenseId: commRootLicenseId,
                isCommercial: true,
                ipaId: 0
            }),
            new bytes[](0),
            new bytes[](0)
        );
        // Non Commercial
        Licensing.License memory license = licenseRegistry.getLicense(lId);
        assertTrue(license.isCommercial);
        assertEq(licenseRegistry.ownerOf(lId), lnftOwner);
        assertEq(licenseRegistry.getLicensee(lId), lnftOwner);
        assertEq(license.revoker, ipOrg.owner());

        // TODO: LicenseRegistry should be able to locate parent licensee
        //assertEq(license.licensor, ipaOwner, "licensor");

        assertTerms(license);
        assertLicenseRelatedWithIpa(lId, rootIpaId, false);
        assertIsSublicenseOf(lId, commRootLicenseId, true);
    }

}
