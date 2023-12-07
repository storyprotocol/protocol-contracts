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
import { PIPLicensingTerms } from "contracts/lib/modules/PIPLicensingTerms.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";

contract LicensingModuleLicensingTest is BaseTest {
    using ShortStrings for *;

    address internal ipaOwner = address(0x13336);
    Licensing.ParamValue[] internal params;

    uint256 internal ipaId_1;
    uint256 internal ipaId_2;

    modifier withFrameworkConfig(
        bool derivativesWithApproval,
        bool reciprocal,
        Licensing.LicensorConfig licensorConfig
    ) {
        ShortString[] memory channels = new ShortString[](2);
        channels[0] = "test1".toShortString();
        channels[1] = "test2".toShortString();
        params.push(
            Licensing.ParamValue({
                tag: PIPLicensingTerms.CHANNELS_OF_DISTRIBUTION.toShortString(),
                value: abi.encode(channels)
            })
        );
        params.push(
            Licensing.ParamValue({
                tag: PIPLicensingTerms.ATTRIBUTION.toShortString(),
                value: "" // unset
            })
        );
        params.push(
            Licensing.ParamValue({
                tag: PIPLicensingTerms
                    .DERIVATIVES_WITH_ATTRIBUTION
                    .toShortString(),
                value: abi.encode(true)
            })
        );
        params.push(
            Licensing.ParamValue({
                tag: PIPLicensingTerms
                    .DERIVATIVES_WITH_APPROVAL
                    .toShortString(),
                value: abi.encode(derivativesWithApproval)
            })
        );
        params.push(
            Licensing.ParamValue({
                tag: PIPLicensingTerms
                    .DERIVATIVES_WITH_RECIPROCAL_LICENSE
                    .toShortString(),
                value: abi.encode(reciprocal)
            })
        );

        Licensing.LicensingConfig memory config = Licensing.LicensingConfig({
            frameworkId: PIPLicensingTerms.FRAMEWORK_ID,
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

        Licensing.ParamDefinition[] memory paramDefs = PIPLicensingTerms
            ._getParamDefs();
        Licensing.SetFramework memory framework = Licensing.SetFramework({
            id: PIPLicensingTerms.FRAMEWORK_ID,
            textUrl: "text_url",
            paramDefs: paramDefs
        });
        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(framework);
    }

    function test_LicensingModule_createLicense_noParent_ipa_userSetsParam()
        public
        withFrameworkConfig(
            true,
            true,
            Licensing.LicensorConfig.IpOrgOwnerAlways
        )
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

        _assertLicenseParams(parentParams, childParams);
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

    // function test_LicensingModule_revert_createAction_InvalidLicensorConfig()
    //     public
    //     withFrameworkConfig(true, true, Licensing.LicensorConfig(uint(10000)))
    // {
    //     uint256 _parentLicenseId = 0; // no parent
    //     Licensing.ParamValue[] memory inputParams = _constructInputParams();
    //     Licensing.LicenseCreation memory creation = Licensing.LicenseCreation({
    //         params: inputParams,
    //         parentLicenseId: _parentLicenseId,
    //         ipaId: ipaId_1
    //     });
    //     vm.prank(ipOrg.owner());
    //     vm.expectRevert(Errors.LicensingModule_IpOrgFrameworkNotSet.selector);
    //     spg.createLicense(
    //         address(ipOrg),
    //         creation,
    //         new bytes[](0),
    //         new bytes[](0)
    //     );
    // }

    function _constructInputParams()
        internal
        pure
        returns (Licensing.ParamValue[] memory)
    {
        Licensing.ParamValue[] memory inputParams = new Licensing.ParamValue[](
            1
        );
        inputParams[0] = Licensing.ParamValue({
            tag: PIPLicensingTerms.ATTRIBUTION.toShortString(),
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
            PIPLicensingTerms.FRAMEWORK_ID
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
        // assertEq(lParams[1].value, inputParams[0].value); // TODO: check this, set by user
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
