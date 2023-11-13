// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "test/foundry/utils/BaseTest.sol";
import "contracts/modules/relationships/RelationshipModule.sol";
import "contracts/lib/modules/LibRelationship.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { TermCategories, TermIds } from "contracts/lib/modules/LicensingTerms.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { BaseLicensingTest } from "./BaseLicensingTest.sol";

contract LicensingCreatorLicensingTest is BaseLicensingTest {
    using ShortStrings for *;

    address ipaOwner = address(0x13333);
    address lnftOwner = address(0x13334);

    function setUp() public override {
        super.setUp();
        registry.register(
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
        withNonCommFramework
    {
        vm.prank(ipOrg.owner());
        uint256 lId = spg.createLicense(
            address(ipOrg),
            Licensing.LicenseCreationParams({
                parentLicenseId: 0,
                isCommercial: false,
                ipaId: 1
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
        assertTrue(
            relationshipModule.relationshipExists(
                LibRelationship.Relationship({
                    relType: ProtocolRelationships.IPA_LICENSE,
                    srcAddress: address(licenseRegistry),
                    srcId: 1,
                    dstAddress: address(registry),
                    dstId: 1
                })
            )
        );
    }

    function test_LicensingModule_licensing_createsCommercialSubLicense_noDestIpa()
        public
        withCommFramework
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
        assertEq(license.revoker, ipOrg.owner());
        // TODO: LicenseRegistry should be able to locate parent licensee
        //assertEq(license.licensor, ipaOwner, "licensor");

        assertTerms(license);
        assertFalse(
            relationshipModule.relationshipExists(
                LibRelationship.Relationship({
                    relType: ProtocolRelationships.IPA_LICENSE,
                    srcAddress: address(licenseRegistry),
                    srcId: lId,
                    dstAddress: address(registry),
                    dstId: 1
                })
            )
        );
        assertTrue(
            relationshipModule.relationshipExists(
                LibRelationship.Relationship({
                    relType: ProtocolRelationships.SUBLICENSE_OF,
                    srcAddress: address(licenseRegistry),
                    srcId: lId,
                    dstAddress: address(licenseRegistry),
                    dstId: commRootLicenseId
                })
            )
        );
    }

    function test_LicensingModule_licensing_createsNonCommercialSubLicense_noDestIpa()
        public
        withNonCommFramework
        withRootLicense(false)
    {

    }

    // TODO sublicense to make a derivate IPA 
    // TODO sublicense for a derivative IPA with exisiting derivative IPA
    // TODO turn sublicense to make a derivative IPA into a derivative IPA with a license
}
