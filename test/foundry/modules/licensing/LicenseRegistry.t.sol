/* solhint-disable contract-name-camelcase, func-name-mixedcase, var-name-mixedcase */
// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { SPUMLParams } from "contracts/lib/modules/SPUMLParams.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { BitMask } from "contracts/lib/BitMask.sol";

// TODO: test on derivativeNeedsApproval = false
contract LicenseRegistryTest is BaseTest {
    using ShortStrings for *;

    event LicenseRegistered(uint256 indexed id);
    event LicenseNftLinkedToIpa(
        uint256 indexed licenseId,
        uint256 indexed ipAssetId
    );
    event LicenseActivated(uint256 indexed licenseId);
    event LicenseRevoked(uint256 indexed licenseId);

    address internal ipaOwner = address(0x13336);
    Licensing.ParamValue[] internal params;

    uint256 internal ipaId_1;
    uint256 internal ipaId_2;

    modifier withFrameworkConfig(
        bool allowsDerivatives,
        bool derivativesWithApproval,
        bool reciprocal,
        Licensing.LicensorConfig licensorConfig
    ) {
        ShortString[] memory channels = new ShortString[](2);
        channels[0] = "test1".toShortString();
        channels[1] = "test2".toShortString();
        params.push(Licensing.ParamValue({
            tag: SPUMLParams.CHANNELS_OF_DISTRIBUTION.toShortString(),
            value: abi.encode(channels)
        }));
        params.push(Licensing.ParamValue({
            tag: SPUMLParams.ATTRIBUTION.toShortString(),
            value: ""// unset
        }));
        params.push(Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            value: abi.encode(allowsDerivatives)
        }));
        uint8[] memory indexes = new uint8[](2);
        if (derivativesWithApproval) {
            indexes[0] = SPUMLParams.ALLOWED_WITH_APPROVAL_INDEX;
        }
        if (reciprocal) {
            indexes[1] = SPUMLParams.ALLOWED_WITH_RECIPROCAL_LICENSE_INDEX;
        }
        uint256 derivativeOptions = BitMask.convertToMask(indexes);
        params.push(Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            value: abi.encode(derivativeOptions)
        }));
        Licensing.LicensingConfig memory config = Licensing.LicensingConfig({
            frameworkId: SPUMLParams.FRAMEWORK_ID,
            params: params,
            licensor: licensorConfig
        });
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(address(ipOrg), config);
        _;
    }


    function setUp() public override {
        super.setUp();
        (ipaId_1, ) = _createIpAsset(ipaOwner, 1, bytes(""));
        (ipaId_2, ) = _createIpAsset(ipaOwner, 1, bytes(""));

        Licensing.ParamDefinition[] memory paramDefs = SPUMLParams
            .getParamDefs();
        Licensing.SetFramework memory framework = Licensing.SetFramework({
            id: SPUMLParams.FRAMEWORK_ID,
            textUrl: "text_url",
            paramDefs: paramDefs
        });
        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(framework);
    }

    function _createLicense_noParent_ipa()
        internal
        withFrameworkConfig(true, true, true, Licensing.LicensorConfig.IpOrgOwnerAlways)
        returns (uint256)
    {
        uint256 _parentLicenseId = 0; // no parent
        Licensing.ParamValue[] memory inputParams = _constructInputParams();
        Licensing.LicenseCreation memory creation = Licensing.LicenseCreation({
            params: inputParams,
            parentLicenseId: _parentLicenseId,
            ipaId: ipaId_1
        });
        vm.prank(ipOrg.owner());
        uint256 licenseId = spg.createLicense(
            address(ipOrg),
            creation,
            new bytes[](0),
            new bytes[](0)
        );
        return licenseId;
    }

    function _createLicense_parent_noIpa_reciprocal()
        public
        returns (uint256 parentLicenseId, uint256 childLicenseId)
    {
        parentLicenseId = _createLicense_noParent_ipa();
        uint256 _ipaId = 0; // no ipa
        Licensing.LicenseCreation memory creation = Licensing.LicenseCreation({
            params: new Licensing.ParamValue[](0),
            parentLicenseId: parentLicenseId,
            ipaId: _ipaId
        });
        vm.prank(ipOrg.owner());
        childLicenseId = spg.createLicense(
            address(ipOrg),
            creation,
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(childLicenseId, 2, "childLicenseId");
    }

    function test_LicenseRegistry_activateLicense()
        public
        returns (uint256 licenseId)
    {
        (
            ,
            licenseId
        ) = _createLicense_parent_noIpa_reciprocal();
        vm.prank(ipOrg.owner());
        vm.expectEmit(address(licenseRegistry));
        emit LicenseActivated(licenseId);
        spg.activateLicense(address(ipOrg), licenseId);
        Licensing.LicenseData memory license = licenseRegistry.getLicenseData(
            licenseId
        );
        assertEq(
            uint8(license.status),
            uint8(Licensing.LicenseStatus.Active),
            "license status"
        );
    }

    function test_LicenseRegistry_revokeLicense()
        public
        returns (uint256 licenseId)
    {
        licenseId = test_LicenseRegistry_activateLicense();

        vm.prank(licenseRegistry.getRevoker(licenseId));
        vm.expectEmit(address(licenseRegistry));
        emit LicenseRevoked(licenseId);
        licenseRegistry.revokeLicense(licenseId);

        // TODO: also check for change IPA status once implemented
        Licensing.LicenseData memory license = licenseRegistry.getLicenseData(
            licenseId
        );
        assertEq(
            uint8(license.status),
            uint8(Licensing.LicenseStatus.Revoked),
            "license status"
        );
    }

		function test_LicenseRegistry_revert_revokeLicense_CallerNotRevoker() external {
        uint256 licenseId = test_LicenseRegistry_activateLicense();
        vm.expectRevert(Errors.LicenseRegistry_CallerNotRevoker.selector);
        licenseRegistry.revokeLicense(licenseId);
    }

    function test_LicenseRegistry_revert_CallerNotLicensingModule_noParent_ipa()
        public
    {
        uint256 licenseId = _createLicense_noParent_ipa();
        Licensing.LicenseData memory license = licenseRegistry.getLicenseData(
            licenseId
        );
        vm.expectRevert(
            Errors.LicenseRegistry_CallerNotLicensingModule.selector
        );
        licenseRegistry.addLicense(license, msg.sender, params);
    }

    function test_LicenseRegistry_revert_CallerNotLicensingModule_parent_noIpa()
        public
    {
        (
            ,
            uint256 licenseId
        ) = _createLicense_parent_noIpa_reciprocal();
        Licensing.LicenseData memory license = licenseRegistry.getLicenseData(
            licenseId
        );
        vm.expectRevert(
            Errors.LicenseRegistry_CallerNotLicensingModule.selector
        );
        licenseRegistry.addLicense(license, msg.sender, params);
    }

    function test_LicenseRegistry_revert_CallerNotLicensor_noParent_ipa()
        public
    {
        uint256 licenseId = _createLicense_noParent_ipa();
        vm.expectRevert(Errors.LicenseRegistry_CallerNotLicensor.selector);
        spg.activateLicense(address(ipOrg), licenseId);
    }

    function test_LicenseRegistry_revert_CallerNotLicensor_parent_noIpa()
        public
    {
        (
            ,
            uint256 licenseId
        ) = _createLicense_parent_noIpa_reciprocal();
        vm.expectRevert(Errors.LicenseRegistry_CallerNotLicensor.selector);
        spg.activateLicense(address(ipOrg), licenseId);
    }

    function test_LicenseRegistry_getLicenseData_noParent_ipa() public {
        uint256 licenseId = _createLicense_noParent_ipa();
        _assertLicenseData(
            licenseRegistry.getLicenseData(licenseId),
            licenseId,
            Licensing.LicenseStatus.Active,
            true,
            true,
            0, // no parent
            ipaId_1
        );
        _assertLicenseParams(licenseRegistry.getParams(licenseId), params);
    }

    function test_LicenseRegistry_getLicenseData_parent_noIpa() public {
        (
            uint256 parentLicenseId,
            uint256 childLicenseId
        ) = _createLicense_parent_noIpa_reciprocal();
        _assertLicenseData(
            licenseRegistry.getLicenseData(childLicenseId),
            childLicenseId,
            // parent derivativeNeedsApproval = true, so child is pending
            Licensing.LicenseStatus.PendingLicensorApproval,
            true,
            true,
            parentLicenseId,
            0 // no ipa
        );

        Licensing.ParamValue[] memory parentParams = licenseRegistry.getParams(
            parentLicenseId
        );
        Licensing.ParamValue[] memory childParams = licenseRegistry.getParams(
            childLicenseId
        );

        _assertLicenseParams(parentParams, childParams);
        // additional for license params
        assertEq(parentParams[1].value, childParams[1].value, "attribution");
    }

    function test_LicenseRegistry_linkLnftToIpa() public {
        (
            ,
            uint256 childLicenseId
        ) = _createLicense_parent_noIpa_reciprocal();

        vm.prank(ipOrg.owner());
        spg.activateLicense(address(ipOrg), childLicenseId);

        vm.expectEmit(address(licenseRegistry));
        emit LicenseNftLinkedToIpa(childLicenseId, ipaId_2);
        vm.prank(address(licensingModule));
        licenseRegistry.linkLnftToIpa(childLicenseId, ipaId_2);
    }

    function test_LicenseRegistry_revert_linkLnftToIpa_LicenseAlreadyLinkedToIpa()
        public
    {
        (
            ,
            uint256 licenseId
        ) = _createLicense_parent_noIpa_reciprocal();

        vm.prank(ipOrg.owner());
        spg.activateLicense(address(ipOrg), licenseId);

        vm.prank(ipOrg.owner());
        licenseRegistry.linkLnftToIpa(licenseId, ipaId_1);

        vm.prank(ipOrg.owner());
        vm.expectRevert(
            Errors.LicenseRegistry_LicenseAlreadyLinkedToIpa.selector
        );
        licenseRegistry.linkLnftToIpa(licenseId, ipaId_1);
    }

    function test_LicenseRegistry_revert_linkLnftToIpa_LicenseRegistry_IPANotActive()
        public
    {
        (
            ,
            uint256 licenseId
        ) = _createLicense_parent_noIpa_reciprocal();

        vm.prank(ipOrg.owner());
        spg.activateLicense(address(ipOrg), licenseId);

        uint256 _ipaId = 123_789; // some id that's not active

        vm.prank(ipOrg.owner());
        vm.expectRevert(Errors.LicenseRegistry_IPANotActive.selector);
        licenseRegistry.linkLnftToIpa(licenseId, _ipaId);
    }

    function test_LicenseRegistry_revert_linkLnftToIpa_LicenseNotActive()
        public
    {
        (
            ,
            uint256 childLicenseId
        ) = _createLicense_parent_noIpa_reciprocal();
        vm.prank(ipOrg.owner());
        vm.expectRevert(Errors.LicenseRegistry_LicenseNotActive.selector);
        licenseRegistry.linkLnftToIpa(childLicenseId, ipaId_1);
    }

    function test_LicenseRegistry_metadata() public {
        (
            ,
            uint256 childLicenseId
        ) = _createLicense_parent_noIpa_reciprocal();
        string memory expected = "data:application/json;base64,eyJuYW1lIjogIlN0b3J5IFByb3RvY29sIExpY2Vuc2UgTkZUICMyIiwgImRlc2NyaXB0aW9uIjogIkxpY2Vuc2UgYWdyZWVtZW50IHN0YXRpbmcgdGhlIHRlcm1zIG9mIGEgU3RvcnkgUHJvdG9jb2wgSVAgT3JnIiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogIklQIE9yZyIsICJ2YWx1ZSI6ICIweGY1YmEyMTY5MWE4YmMwMTFiN2I0MzA4NTRiNDFkNWJlMGI3OGI5MzgifSx7InRyYWl0X3R5cGUiOiAiRnJhbWV3b3JrIElEIiwgInZhbHVlIjogIlNQVU1MLTEuMCJ9LHsidHJhaXRfdHlwZSI6ICJGcmFtZXdvcmsgVVJMIiwgInZhbHVlIjogInRleHRfdXJsIn0seyJ0cmFpdF90eXBlIjogIlN0YXR1cyIsICJ2YWx1ZSI6ICJQZW5kaW5nIExpY2Vuc29yIEFwcHJvdmFsIn0seyJ0cmFpdF90eXBlIjogIkxpY2Vuc29yIiwgInZhbHVlIjogIjB4MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDFjOCJ9LHsidHJhaXRfdHlwZSI6ICJMaWNlbnNlZSIsICJ2YWx1ZSI6ICIweDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAxYzgifSx7InRyYWl0X3R5cGUiOiAiUmV2b2tlciIsICJ2YWx1ZSI6ICIweDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAyMmIifSx7InRyYWl0X3R5cGUiOiAiUGFyZW50IExpY2Vuc2UgSUQiLCAidmFsdWUiOiAiMSJ9LHsidHJhaXRfdHlwZSI6ICJEZXJpdmF0aXZlIElQQSIsICJ2YWx1ZSI6ICIwIn0seyJ0cmFpdF90eXBlIjogIkNoYW5uZWxzLU9mLURpc3RyaWJ1dGlvbiIsICJ2YWx1ZSI6IFsidGVzdDEiLCJ0ZXN0MiJdfSx7InRyYWl0X3R5cGUiOiAiQXR0cmlidXRpb24iLCAidmFsdWUiOiAidHJ1ZSJ9LHsidHJhaXRfdHlwZSI6ICJEZXJpdmF0aXZlcy1BbGxvd2VkIiwgInZhbHVlIjogInRydWUifSx7InRyYWl0X3R5cGUiOiAiRGVyaXZhdGl2ZXMtQWxsb3dlZC1PcHRpb25zIiwgInZhbHVlIjogWyJBbGxvd2VkLVdpdGgtQXBwcm92YWwiLCJBbGxvd2VkLVJlY2lwcm9jYWwtTGljZW5zZSJdfV19";
        assertEq(licenseRegistry.tokenURI(childLicenseId), expected);

    }

    function _constructInputParams()
        internal
				pure
        returns (Licensing.ParamValue[] memory)
    {
        Licensing.ParamValue[] memory inputParams = new Licensing.ParamValue[](
            1
        );
        inputParams[0] = Licensing.ParamValue({
            tag: SPUMLParams.ATTRIBUTION.toShortString(),
            value: abi.encode(true)
        });
        return inputParams;
    }

    function _assertLicenseData(
        Licensing.LicenseData memory license,
        uint256 licenseId,
        Licensing.LicenseStatus expectedLicenseStatus,
        bool expectedIsReciprocal,
        bool expectedDerivativeNeedsApproval,
        uint256 expectedParentLicenseId,
        uint256 expectedIpaId
    ) internal {
        assertEq(
            uint8(license.status),
            uint8(expectedLicenseStatus),
            "licenseStatus"
        );
        assertEq(
            license.isReciprocal,
            licenseRegistry.isReciprocal(licenseId),
            "isReciprocal A"
        );
        assertEq(license.isReciprocal, expectedIsReciprocal, "isReciprocal B");
        assertEq(
            license.derivativeNeedsApproval,
            licenseRegistry.derivativeNeedsApproval(licenseId),
            "derivativeNeedsApproval A"
        );
        assertEq(
            license.derivativeNeedsApproval,
            expectedDerivativeNeedsApproval,
            "derivativeNeedsApproval B"
        );
        assertEq(
            license.revoker,
            licenseRegistry.getRevoker(licenseId),
            "revoker A"
        );
        assertEq(
            license.revoker,
            licensingModule.DEFAULT_REVOKER(),
            "revoker B"
        );
        assertEq(
            license.licensor,
            licenseRegistry.getLicensor(licenseId),
            "licensor A"
        );
        assertEq(license.licensor, ipOrg.owner(), "licensor B");
        assertEq(license.ipOrg, licenseRegistry.getIPOrg(licenseId), "ipOrg A");
        assertEq(license.ipOrg, address(ipOrg), "ipOrg B");
        assertEq(
            license.frameworkId.toString(),
            SPUMLParams.FRAMEWORK_ID
        );
        assertEq(license.ipaId, licenseRegistry.getIpaId(licenseId), "ipaId A");
        assertEq(license.ipaId, expectedIpaId, "ipaId B");
        assertEq(
            license.parentLicenseId,
            licenseRegistry.getParentLicenseId(licenseId),
            "parentLicenseId A"
        );
        assertEq(
            license.parentLicenseId,
            expectedParentLicenseId,
            "parentLicenseId B"
        );
    }

    function _assertLicenseParams(
        Licensing.ParamValue[] memory lParams,
        Licensing.ParamValue[] memory rParams
    ) internal {
        assertEq(
            lParams[0].tag.toString(),
            rParams[0].tag.toString(),
            "channel of distribution"
        );
        assertEq(lParams[0].value, rParams[0].value, "channel of distribution");
        assertEq(
            lParams[1].tag.toString(),
            rParams[1].tag.toString(),
            "attribution"
        );
        // assertEq(lParams[1].value, inputParams[0].value); // Set by user
        assertEq(
            lParams[2].tag.toString(),
            rParams[2].tag.toString(),
            "derivatives with attribution"
        );
        assertEq(
            lParams[2].value,
            rParams[2].value,
            "derivatives with attribution"
        );
        assertEq(
            lParams[3].tag.toString(),
            rParams[3].tag.toString(),
            "derivatives with approval"
        );
        assertEq(
            lParams[3].value,
            rParams[3].value,
            "derivatives with approval"
        );
    }
}
