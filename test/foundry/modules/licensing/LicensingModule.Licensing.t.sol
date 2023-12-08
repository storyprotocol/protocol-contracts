/* solhint-disable contract-name-camelcase, func-name-mixedcase, var-name-mixedcase */
// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { SPUMLParams } from "contracts/lib/modules/SPUMLParams.sol";
import { BitMask } from "contracts/lib/BitMask.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract LicensingModuleLicensingTest is BaseTest {
    using ShortStrings for *;
    using BitMask for uint256;

    address internal ipaOwner = address(0x13336);
    Licensing.ParamValue[] internal ipOrgParams;

    event LicenseNftLinkedToIpa(uint256 licenseId, uint256 ipAssetId);

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
        ipOrgParams.push(Licensing.ParamValue({
            tag: SPUMLParams.CHANNELS_OF_DISTRIBUTION.toShortString(),
            value: abi.encode(channels)
        }));
        ipOrgParams.push(Licensing.ParamValue({
            tag: SPUMLParams.ATTRIBUTION.toShortString(),
            value: ""// unset
        }));
        ipOrgParams.push(Licensing.ParamValue({
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
        ipOrgParams.push(Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            value: abi.encode(derivativeOptions)
        }));
        Licensing.LicensingConfig memory config = Licensing.LicensingConfig({
            frameworkId: SPUMLParams.FRAMEWORK_ID,
            params: ipOrgParams,
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
    
    function test_LicensingModule_createLicense_noParent_ipa_userSetsParam()
    withFrameworkConfig(true, true, true, Licensing.LicensorConfig.IpOrgOwnerAlways)
    public returns (uint256) {
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

        _assertLicenseData(
            licenseRegistry.getLicenseData(licenseId),
            licenseId,
            Licensing.LicenseStatus.Active,
            true,
            true,
            0, // no parent
            ipaId_1
        );
        _assertLicenseParams(licenseRegistry.getParams(licenseId), ipOrgParams, inputParams);

        return licenseId;
    }

    function test_LicensingModule_createLicense_parent_noIpa_reciprocal()
        public
        returns (uint256 parentLicenseId, uint256 childLicenseId)
    {
        parentLicenseId = test_LicensingModule_createLicense_noParent_ipa_userSetsParam();
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

        _assertLicenseParams(parentParams, childParams, new Licensing.ParamValue[](0));
        // additional for license params
        assertEq(parentParams[1].value, childParams[1].value, "attribution");
    }

    function test_LicensingModule_revert_addReciprocalLicense_ParentLicenseNotActive()
        public
    {
        uint256 parentLicenseId = test_LicensingModule_createLicense_noParent_ipa_userSetsParam();
        Licensing.LicenseCreation memory creation = Licensing.LicenseCreation({
            params: new Licensing.ParamValue[](0),
            parentLicenseId: parentLicenseId,
            ipaId: 0
        });

        vm.prank(ipOrg.owner());
        uint256 childLicenseId = spg.createLicense(
            address(ipOrg),
            creation,
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(childLicenseId, 2);
        Licensing.LicenseData memory license = licenseRegistry.getLicenseData(childLicenseId);
        assertEq(uint8(license.status), uint8(Licensing.LicenseStatus.PendingLicensorApproval));
        assertEq(license.derivativesAllowed, true, "derivativesAllowed");
        assertEq(license.isReciprocal, true, "isReciprocal");
        assertEq(license.derivativeNeedsApproval, true, "derivativeNeedsApproval");
        assertEq(license.revoker, licensingModule.DEFAULT_REVOKER());
        assertEq(license.licensor, ipOrg.owner());
        assertEq(license.ipOrg, address(ipOrg));
        assertEq(license.frameworkId.toString(), SPUMLParams.FRAMEWORK_ID);
        assertEq(license.ipaId, 0, "ipaId");
        assertEq(license.parentLicenseId, parentLicenseId);
        Licensing.ParamValue[] memory parentParams = licenseRegistry.getParams(parentLicenseId);
        Licensing.ParamValue[] memory childParams = licenseRegistry.getParams(childLicenseId);
        assertEq(parentParams[0].tag.toString(), childParams[0].tag.toString(), "channel of distribution");
        assertEq(parentParams[0].value, childParams[0].value, "channel of distribution");
        assertEq(parentParams[1].tag.toString(), childParams[1].tag.toString(), "attribution");
        assertEq(parentParams[1].value, childParams[1].value, "attribution");
        assertEq(parentParams[2].tag.toString(), childParams[2].tag.toString(), "derivatives with attribution");
        assertEq(parentParams[2].value, childParams[2].value, "derivatives with attribution");
        assertEq(parentParams[3].tag.toString(), childParams[3].tag.toString(), "derivatives with approval");
        assertEq(parentParams[3].value, childParams[3].value, "derivatives with approval");
    }

    function test_LicensingModule_linkLnftToIpa_onIpaCreation() public {
        (
            ,
            uint256 childLicenseId
        ) = test_LicensingModule_createLicense_parent_noIpa_reciprocal();

        vm.prank(ipOrg.owner());
        spg.activateLicense(address(ipOrg), childLicenseId);
        address licenseOwner = licenseRegistry.ownerOf(childLicenseId);

        
        // vm.expectEmit(address(licenseRegistry));
        // emit LicenseNftLinkedToIpa(childLicenseId, 3);
        _createIpAssetAndLinkLicense(
            licenseOwner,
            1,
            childLicenseId,
            bytes("")
        );
        assertEq(licenseRegistry.getIpaId(childLicenseId), 3);
    }
    
    function test_LicensingModule_revert_performAction_InvalidAction() public {
        vm.prank(address(spg)); // spg has AccessControl.MODULE_EXECUTOR_ROLE access
        vm.expectRevert(Errors.LicensingModule_InvalidAction.selector);
        moduleRegistry.execute(
            IIPOrg(ipOrg),
            address(this),
            ModuleRegistryKeys.LICENSING_MODULE,
            abi.encode("INVALID_ACTION", abi.encode(0, ipaId_1)),
            new bytes[](0),
            new bytes[](0)
        );
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
        Licensing.ParamValue[] memory rParams,
        Licensing.ParamValue[] memory inputParams
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
        if (inputParams.length == 0) {
            assertEq(lParams[1].value, rParams[1].value, "attribution");
        } else {
            assertEq(lParams[1].value, inputParams[0].value, "attribution");
        }
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
