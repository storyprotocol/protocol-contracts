/* solhint-disable contract-name-camelcase, func-name-mixedcase, var-name-mixedcase */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { RegistrationModule } from "contracts/modules/registration/RegistrationModule.sol";
import { StoryProtocol } from "contracts/StoryProtocol.sol";
import { RelationshipModule } from "contracts/modules/relationships/RelationshipModule.sol";
import { LicensingModule } from "contracts/modules/licensing/LicensingModule.sol";
import { TokenGatedHook } from "contracts/hooks/TokenGatedHook.sol";
import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";
import { HookResult, IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import { TokenGated } from "contracts/lib/hooks/TokenGated.sol";
import { MockERC721 } from "test/foundry/mocks/MockERC721.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Registration } from "contracts/lib/modules/Registration.sol";
import { IE2ETest } from "test/foundry/interfaces/IE2ETest.sol";
import { PIPLicensingTerms } from "contracts/lib/modules/PIPLicensingTerms.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract E2ETest is IE2ETest, BaseTest {
    using ShortStrings for *;

    address internal tokenGatedHook;
    MockERC721 internal mockNFT;

    address internal ipOrgOwner1 = address(1234);
    address internal ipOrgOwner2 = address(4567);
    address internal ipAssetOwner1 = address(6789);
    address internal ipAssetOwner2 = address(9876);
    address internal ipAssetOwner3 = address(8888);

    address internal ipOrg1;
    address internal ipOrg2;

    string internal FRAMEWORK_ID_DOGnCO = "test_framework_dog_and_co";
    string internal FRAMEWORK_ID_CATnCO = "test_framework_cat_and_co";

    // variables defined here to avoid stack too deep error
    bytes[] internal preHooksDataStory;
    bytes[] internal preHooksDataCharacter;
    bytes[] internal hooksTransferIPAsset;
    uint256 internal licenseId_1_nonDeriv;
    uint256 internal licenseId_2_deriv;
    uint256 internal licenseId_3_deriv;
    uint256 internal ipAssetId_1;
    uint256 internal ipAssetId_2;
    uint256 internal ipAssetId_3;
    uint256 internal ipOrg1_AssetId_1;
    uint256 internal ipOrg1_AssetId_2;
    uint256 internal ipOrg2_AssetId_1;
    uint256 internal relIdProtocolLevel;

    function setUp() public virtual override {
        super.setUp();
        _grantRole(vm, AccessControl.RELATIONSHIP_MANAGER_ROLE, admin);
        _grantRole(vm, AccessControl.LICENSING_MANAGER, admin);
        _grantRole(
            vm,
            AccessControl.HOOK_CALLER_ROLE,
            address(registrationModule)
        );
        _grantRole(
            vm,
            AccessControl.HOOK_CALLER_ROLE,
            address(relationshipModule)
        );
        _grantRole(
            vm,
            AccessControl.HOOK_CALLER_ROLE,
            address(licensingModule)
        );

        /// TOKEN_GATED_HOOK
        tokenGatedHook = address(new TokenGatedHook(address(accessControl)));

        /// MOCK_ERC_721
        mockNFT = new MockERC721();
        mockNFT.mint(ipAssetOwner1, 1);
        mockNFT.mint(ipAssetOwner2, 2);

        /// Setups
        _setUp_LicensingFramework();

        vm.label(ipOrgOwner1, "ipOrgOwner1");
        vm.label(ipOrgOwner2, "ipOrgOwner2");
    }

    function _setUp_LicensingFramework() internal {
        /// Licensing Framework (ID: dog & co.)
        Licensing.ParamDefinition[]
            memory fParams = new Licensing.ParamDefinition[](3);
        fParams[0] = Licensing.ParamDefinition({
            tag: "TEST_TAG_DOG_1".toShortString(),
            paramType: Licensing.ParameterType.Bool
        });
        fParams[1] = Licensing.ParamDefinition({
            tag: "TEST_TAG_DOG_2".toShortString(),
            paramType: Licensing.ParameterType.Number
        });
        fParams[2] = Licensing.ParamDefinition({
            tag: "TEST_TAG_DOG_3".toShortString(),
            paramType: Licensing.ParameterType.MultipleChoice
        });
        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(
            Licensing.SetFramework({
                id: FRAMEWORK_ID_DOGnCO,
                textUrl: "text_url_dog_and_co",
                paramDefs: fParams
            })
        );

        /// Licensing Framework (ID: cat and co)
        fParams = new Licensing.ParamDefinition[](1);
        fParams[0] = Licensing.ParamDefinition({
            tag: "TEST_TAG_CAT_1".toShortString(),
            paramType: Licensing.ParameterType.MultipleChoice
        });
        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(
            Licensing.SetFramework({
                id: FRAMEWORK_ID_CATnCO,
                textUrl: "text_url_cat_and_co",
                paramDefs: fParams
            })
        );

        // Licensing Framework (ID: PIPLicensingTerms)
        Licensing.ParamDefinition[] memory paramDefs = PIPLicensingTerms
            ._getParamDefs();
        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(
            Licensing.SetFramework({
                id: PIPLicensingTerms.FRAMEWORK_ID,
                textUrl: "text_url_pip_licensing_terms",
                paramDefs: paramDefs
            })
        );
    }

    function test_e2e() public {
        ///
        /// =========================================
        ///               Create IPOrgs
        /// =========================================
        ///

        string[] memory ipAssetTypesShared = new string[](2);
        string[] memory ipAssetTypesOnly1 = new string[](1);
        string[] memory ipAssetTypesOnly2 = new string[](1);
        ipAssetTypesShared[0] = "CHARACTER";
        ipAssetTypesShared[1] = "STORY";
        ipAssetTypesOnly1[0] = "MOVIE";
        ipAssetTypesOnly2[0] = "MUSIC";

        ipOrg1 = spg.registerIpOrg(
            ipOrgOwner1,
            "IPOrgName1",
            "IPO1",
            ipAssetTypesShared
        );
        ipOrg2 = spg.registerIpOrg(
            ipOrgOwner2,
            "IPOrgName2",
            "IPO2",
            ipAssetTypesShared
        );

        vm.label(ipOrg1, "IPOrg_1");
        vm.label(ipOrg2, "IPOrg_2");

        // TODO: check for event `ModuleConfigured`
        vm.prank(ipOrgOwner1);
        spg.addIPAssetTypes(ipOrg1, ipAssetTypesOnly1);

        vm.prank(ipOrgOwner2);
        spg.addIPAssetTypes(ipOrg2, ipAssetTypesOnly2);

        ///
        /// =========================================
        ///         Configure IPOrg modules
        /// =========================================
        ///

        string memory ipOrg1_baseUri = "http://iporg1.baseuri.url";
        string memory ipOrg2_baseUri = "http://iporg2.baseuri.url";
        string memory ipOrg1_contractUri = "http://iporg1.contracturi.url";
        string memory ipOrg2_contractUri = "http://iporg2.contracturi.url";

        vm.expectEmit(address(registrationModule));
        emit MetadataUpdated(ipOrg1, ipOrg1_baseUri, ipOrg1_contractUri);
        vm.prank(ipOrgOwner1);
        spg.setMetadata(ipOrg1, ipOrg1_baseUri, ipOrg1_contractUri);
        assertEq(
            registrationModule.contractURI(ipOrg1),
            ipOrg1_contractUri,
            "contractURI should be ipOrg1_contractUri"
        );
        assertEq(
            IIPOrg(ipOrg1).contractURI(),
            ipOrg1_contractUri,
            "contractURI should be ipOrg1_contractUri"
        );
        // TODO: tokenURI check
        // assertEq(registrationModule.tokenURI(address(ipOrg), 1, 0), "");

        vm.prank(ipOrgOwner2);
        spg.setMetadata(ipOrg2, ipOrg2_baseUri, ipOrg2_contractUri);
        assertEq(
            registrationModule.contractURI(ipOrg2),
            ipOrg2_contractUri,
            "contractURI should be ipOrg2_contractUri"
        );
        assertEq(
            IIPOrg(ipOrg2).contractURI(),
            ipOrg2_contractUri,
            "contractURI should be ipOrg2_contractUri"
        );

        ///
        /// =========================================
        ///   Register hooks via RegistrationModule
        /// =========================================
        ///

        // Add token gated hook
        address[] memory hooks = new address[](1);
        hooks[0] = tokenGatedHook;

        // Specify the configuration for the token gated hook, ie. which token to use
        bytes[] memory hooksConfig = new bytes[](1);
        TokenGated.Config memory tokenGatedConfig = TokenGated.Config({
            tokenAddress: address(mockNFT)
        });
        hooksConfig[0] = abi.encode(tokenGatedConfig);

        vm.expectEmit(address(registrationModule));
        emit HooksRegistered(
            HookRegistry.HookType.PreAction,
            keccak256(abi.encode(ipOrg1, "REGISTRATION")),
            hooks
        );
        vm.prank(ipOrgOwner1);
        // Register hooks for ipOrg1 as pre-action hooks
        RegistrationModule(registrationModule).registerHooks(
            HookRegistry.HookType.PreAction,
            IIPOrg(ipOrg1),
            hooks,
            hooksConfig
        );

        ///
        /// =========================================
        ///           Add Relationship types
        /// =========================================
        ///

        LibRelationship.RelatedElements memory allowedElements = LibRelationship
            .RelatedElements({
                src: LibRelationship.Relatables.ADDRESS,
                dst: LibRelationship.Relatables.ADDRESS
            });
        uint8[] memory allowedSrcs = new uint8[](2);
        allowedSrcs[0] = 0;
        allowedSrcs[1] = 2;
        uint8[] memory allowedDsts = new uint8[](1);
        allowedDsts[0] = 1;
        LibRelationship.AddRelationshipTypeParams
            memory relProtocolLevelParams = LibRelationship
                .AddRelationshipTypeParams({
                    relType: "TEST_RELATIONSHIP_PROTOCOL_LEVEL",
                    ipOrg: LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
                    allowedElements: allowedElements,
                    allowedSrcs: allowedSrcs,
                    allowedDsts: allowedDsts
                });
        // Admin needs to add protocol-level relationship types
        vm.startPrank(admin);
        spg.addRelationshipType(relProtocolLevelParams);
        spg.removeRelationshipType(
            LibRelationship.PROTOCOL_LEVEL_RELATIONSHIP,
            "TEST_RELATIONSHIP_PROTOCOL_LEVEL"
        );
        spg.addRelationshipType(relProtocolLevelParams);
        vm.stopPrank();

        allowedElements = LibRelationship.RelatedElements({
            src: LibRelationship.Relatables.ADDRESS,
            dst: LibRelationship.Relatables.ADDRESS
        });
        allowedSrcs = new uint8[](0);
        allowedDsts = new uint8[](0);
        LibRelationship.AddRelationshipTypeParams
            memory relAppearInParams = LibRelationship
                .AddRelationshipTypeParams({
                    relType: "APPEAR_IN",
                    ipOrg: ipOrg1,
                    allowedElements: allowedElements,
                    allowedSrcs: allowedSrcs,
                    allowedDsts: allowedDsts
                });
        // TODO: event check for `addRelationshipType` (event `RelationshipTypeSet`)
        vm.prank(ipOrgOwner1);
        spg.addRelationshipType(relAppearInParams);

        ///
        /// =========================================
        ///      Create Relationships for IPOrgs
        ///     based on above Relationship types
        /// =========================================
        ///

        // In IPOrg 1, create a relationship from asset ID 1 to asset ID 2 (local to IPOrg 1)
        // to indicate that ID 1 appears in ID 2
        LibRelationship.CreateRelationshipParams
            memory crParams = LibRelationship.CreateRelationshipParams({
                relType: "APPEAR_IN",
                srcAddress: ipOrg1,
                srcId: 1,
                dstAddress: ipOrg1,
                dstId: 2
            });

        vm.prank(ipOrgOwner1);
        relIdProtocolLevel = spg.createRelationship(
            ipOrg1,
            crParams,
            new bytes[](0), // preHooksDataRel
            new bytes[](0) // postHooksDataRel
        );
        assertEq(relIdProtocolLevel, 1, "relIdProtocolLevel should be 1");
        LibRelationship.Relationship memory rel = relationshipModule
            .getRelationship(1);
        assertEq(rel.relType, "APPEAR_IN", "relType should be APPEAR_IN");
        assertEq(rel.srcAddress, ipOrg1, "srcAddress should be ipOrg1");
        assertEq(rel.dstAddress, ipOrg1, "dstAddress should be ipOrg1");
        assertEq(rel.srcId, 1, "srcId should be 1");
        assertEq(rel.dstId, 2, "dstId should be 2");
        assertTrue(
            relationshipModule.relationshipExists(rel),
            "Relationship should exist"
        );

        ///
        /// =========================================
        ///         Configure IPOrg's Licensing
        /// =========================================
        ///

        //
        // Configure licensing for dog & co.
        //

        Licensing.ParamValue[] memory lParams = new Licensing.ParamValue[](3);
        lParams[0] = Licensing.ParamValue({
            tag: "TEST_TAG_DOG_1".toShortString(),
            value: abi.encode(true)
        });
        lParams[1] = Licensing.ParamValue({
            tag: "TEST_TAG_DOG_2".toShortString(),
            value: abi.encode(222)
        });

        ShortString[] memory ssValue = new ShortString[](2);
        ssValue[0] = "test1".toShortString();
        ssValue[1] = "test2".toShortString();
        lParams[2] = Licensing.ParamValue({
            tag: "TEST_TAG_DOG_3".toShortString(),
            value: abi.encode(ssValue)
        });

        Licensing.LicensingConfig memory licensingConfig1 = Licensing
            .LicensingConfig({
                frameworkId: FRAMEWORK_ID_DOGnCO,
                params: lParams,
                licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
            });

        // TODO: event check for `configureIpOrgLicensing`
        vm.prank(ipOrgOwner1);
        spg.configureIpOrgLicensing(ipOrg1, licensingConfig1);

        //
        // Configure licensing for cat & co.
        //

        ShortString[] memory channels = new ShortString[](2);
        channels[0] = "test1".toShortString();
        channels[1] = "test2".toShortString();

        lParams = new Licensing.ParamValue[](5);
        lParams[0] = Licensing.ParamValue({
            tag: PIPLicensingTerms.CHANNELS_OF_DISTRIBUTION.toShortString(),
            value: abi.encode(channels)
        });
        lParams[1] = Licensing.ParamValue({
            tag: PIPLicensingTerms.ATTRIBUTION.toShortString(),
            value: "" // unset
        });
        lParams[2] = Licensing.ParamValue({
            tag: PIPLicensingTerms.DERIVATIVES_WITH_ATTRIBUTION.toShortString(),
            value: abi.encode(true)
        });
        lParams[3] = Licensing.ParamValue({
            tag: PIPLicensingTerms.DERIVATIVES_WITH_APPROVAL.toShortString(),
            value: abi.encode(true)
        });
        lParams[4] = Licensing.ParamValue({
            tag: PIPLicensingTerms
                .DERIVATIVES_WITH_RECIPROCAL_LICENSE
                .toShortString(),
            value: abi.encode(true)
        });

        Licensing.LicensingConfig memory licensingConfig2 = Licensing
            .LicensingConfig({
                frameworkId: PIPLicensingTerms.FRAMEWORK_ID,
                params: lParams,
                licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
            });

        vm.startPrank(ipOrgOwner2);
        // Two `configureIpOrgLicensing`s are commented out since right now, we allow
        // `configureIpOrgLicensing` to be called only once per IPOrg.
        // spg.configureIpOrgLicensing(ipOrg2, licensingConfig1); // this should get overwritten by Unset
        // spg.configureIpOrgLicensing(ipOrg2, Licensing.LicensingConfig({
        //     frameworkId: PIPLicensingTerms.FRAMEWORK_ID,
        //     params: lParams,
        //     licensor: Licensing.LicensorConfig.Unset
        // }));
        spg.configureIpOrgLicensing(ipOrg2, licensingConfig2);
        vm.stopPrank();

        ///
        /// =========================================
        ///             Register IP Assets
        /// =========================================
        ///

        //
        // Asset ID 1 (Org 1, ID 1)
        //

        Registration.RegisterIPAssetParams
            memory registerIpAssetParamsCharacter = Registration
                .RegisterIPAssetParams({
                    owner: ipAssetOwner1,
                    ipOrgAssetType: 0,
                    name: "Character IPA",
                    hash: 0x558b44f88e5959cec9c7836078a53ff4d6432142a9d5caa6f3a6eb7c83930000,
                    mediaUrl: "https://arweave.net/character"
                });

        TokenGated.Params memory tokenGatedHookDataCharacter = TokenGated
            .Params({ tokenOwner: ipAssetOwner1 });
        preHooksDataCharacter = new bytes[](1);
        preHooksDataCharacter[0] = abi.encode(tokenGatedHookDataCharacter);

        // TODO: Solve "Stack too deep" for emitting this event
        // vm.expectEmit(address(tokenGatedHook));
        // emit SyncHookExecuted(
        //     address(tokenGatedHook),
        //     HookResult.Completed,
        //     _getExecutionContext(hooksConfig[0], abi.encode("")),
        //     ""
        // );
        vm.prank(ipAssetOwner1);
        (ipAssetId_1, ipOrg1_AssetId_1) = spg.registerIPAsset(
            ipOrg1,
            registerIpAssetParamsCharacter,
            preHooksDataCharacter,
            new bytes[](0)
        );
        assertEq(ipAssetId_1, 1, "ipAssetId_1 should be 1");
        assertEq(ipOrg1_AssetId_1, 1, "ipOrg1_AssetId_1 should be 1");

        //
        // Asset ID 2 (Org 1, ID 2)
        //

        Registration.RegisterIPAssetParams
            memory registerIpAssetParamsStory = Registration
                .RegisterIPAssetParams({
                    owner: ipAssetOwner2,
                    ipOrgAssetType: 1,
                    name: "Story IPA",
                    hash: 0x558b44f88e5959cec9c7836078a53ff4d6432142a9d5caa6f3a6eb7c83931111,
                    mediaUrl: "https://arweave.net/story"
                });
        TokenGated.Params memory tokenGatedHookDataStory = TokenGated.Params({
            tokenOwner: ipAssetOwner2
        });
        preHooksDataStory = new bytes[](1);
        preHooksDataStory[0] = abi.encode(tokenGatedHookDataStory);
        vm.prank(ipAssetOwner2);
        (ipAssetId_2, ipOrg1_AssetId_2) = spg.registerIPAsset(
            ipOrg1,
            registerIpAssetParamsStory,
            preHooksDataStory,
            new bytes[](0)
        );
        assertEq(ipAssetId_2, 2, "ipAssetId_2 should be 2");
        assertEq(ipOrg1_AssetId_2, 2, "ipOrg1_AssetId_2 should be 2");

        //
        // Asset ID 3 (Org 2, ID 1)
        //

        Registration.RegisterIPAssetParams
            memory registerIpAssetParamsOrg2 = Registration
                .RegisterIPAssetParams({
                    owner: ipAssetOwner3,
                    ipOrgAssetType: 1,
                    name: "Story IPA Org2",
                    hash: 0x558b44f88e5959cec9c7836078a53ff4d6432142a9d5caa6f3a6eb7c83933333,
                    mediaUrl: "https://arweave.net/story2"
                });
        vm.prank(ipAssetOwner3);
        (ipAssetId_3, ipOrg2_AssetId_1) = spg.registerIPAsset(
            ipOrg2,
            registerIpAssetParamsOrg2,
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(ipAssetId_3, 3, "ipAssetId_3 should be 3");
        assertEq(ipOrg2_AssetId_1, 1, "ipOrg2_AssetId_1 should be 1");

        ///
        /// =========================================
        ///         Change Owners of IP Assets
        /// =========================================
        ///

        hooksTransferIPAsset = new bytes[](1);
        hooksTransferIPAsset[0] = abi.encode(ipAssetOwner1);

        vm.expectEmit(address(registrationModule));
        emit IPAssetTransferred(1, ipOrg1, 1, ipAssetOwner1, ipAssetOwner2);
        vm.prank(ipAssetOwner1);
        spg.transferIPAsset(
            ipOrg1,
            ipAssetOwner1,
            ipAssetOwner2,
            1,
            // BaseModule_HooksParamsLengthMismatc
            hooksTransferIPAsset,
            new bytes[](0)
        );

        ///
        /// =========================================
        ///             Create License NFTs
        ///           for IPOrg2's IP Assets
        /// =========================================
        ///

        vm.prank(address(registrationModule));
        vm.expectEmit(address(registry));
        emit IPOrgTransferred(ipAssetId_2, ipOrg1, ipOrg2);
        registry.transferIPOrg(ipAssetId_2, ipOrg2);
        assertEq(registry.ipAssetOrg(ipAssetId_2), ipOrg2, "IPOrg should be 2");

        // Misc.

        vm.prank(address(0)); // TODO: modify when `onlyDisputer` is complete
        emit StatusChanged(ipAssetId_2, 1, 0); // 0 means unset, 1 means set (change when status is converted to ENUM)
        registry.setStatus(ipAssetId_2, 0);
        assertEq(registry.status(ipAssetId_2), 0, "Status should be unset");

        registry.setStatus(ipAssetId_2, 1); // reset the status to be active

        ///
        /// =========================================
        ///          Create License NFTs (1)
        /// =========================================
        ///

        //
        // Create a license for Asset ID 3 (Org 2, ID 1)
        // Use PIPLicensingTerms license framework, which is attached to Org 2 (cat & co.)
        // Recall that "derivativeNeedsApproval = true" for PIPLicensingTerms
        //

        Licensing.ParamValue[] memory inputParams = new Licensing.ParamValue[](
            1
        );
        inputParams[0] = Licensing.ParamValue({
            tag: PIPLicensingTerms.ATTRIBUTION.toShortString(),
            value: abi.encode(true)
        });
        Licensing.LicenseCreation memory lCreation = Licensing.LicenseCreation({
            params: inputParams,
            parentLicenseId: 0, // no parent
            ipaId: ipAssetId_3
        });
        vm.prank(ipOrgOwner2);
        licenseId_1_nonDeriv = spg.createLicense(
            address(ipOrg2),
            lCreation,
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(licenseId_1_nonDeriv, 1, "License ID should be 1");
        Licensing.LicenseData memory licenseData_1_nonDeriv = licenseRegistry
            .getLicenseData(licenseId_1_nonDeriv);
        assertEq(
            uint8(licenseData_1_nonDeriv.status),
            uint8(Licensing.LicenseStatus.Active),
            "License should active be if it's not a derivative"
        );
        vm.expectRevert(Errors.LicenseRegistry_LicenseNotPendingApproval.selector);
        vm.prank(ipOrgOwner2); // PIPLicensingTerms specifies the licensor as IPOrgOwnerAlways
        spg.activateLicense(address(ipOrg2), licenseId_1_nonDeriv);

        //
        // Create two more licenses for Asset ID 3 (Org 2, ID 1), this time with a parent license
        // (licenseId_1_nonDeriv created above), so this is a sub-license.
        //
        // Since `licenseId_1_nonDeriv` is reciprocal (as we've configured for PIPLicensingTerms),
        // the two sub-licenses can't modify the params, ie. they inherit the parent's params.
        //
        // First sub-license is created without a linked IP asset, second sub-license is created with a linked IP asset.
        //

        //
        // First once should have no IP asset linked on creation
        //

        lCreation = Licensing.LicenseCreation({
            params: new Licensing.ParamValue[](0),
            parentLicenseId: licenseId_1_nonDeriv,
            ipaId: 0 // no linked IP asset
        });
        vm.prank(ipOrgOwner2);
        licenseId_2_deriv = spg.createLicense(
            address(ipOrg2),
            lCreation,
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(licenseId_2_deriv, 2, "License ID should be 2");
        Licensing.LicenseData memory licenseData_2_derive = licenseRegistry
            .getLicenseData(licenseId_2_deriv);
        assertEq(
            uint8(licenseData_2_derive.status),
            uint8(Licensing.LicenseStatus.PendingLicensorApproval),
            "License should pending approval be if it's a derivative"
        );

        // Because we set the licensorConfig to `Licensing.LicensorConfig.IpOrgOwnerAlways` in PIPLicensingTerms,
        // the licensor is ipOrgOwner2.
        vm.prank(ipOrgOwner2);
        spg.activateLicense(address(ipOrg2), licenseId_2_deriv);
        licenseData_2_derive = licenseRegistry
            .getLicenseData(licenseId_2_deriv); // refresh license data cached in memory
        assertEq(
            uint8(licenseData_2_derive.status),
            uint8(Licensing.LicenseStatus.Active),
            "License should be active"
        );

        //
        // Second one should have an IP asset linked on creation
        //

        lCreation = Licensing.LicenseCreation({
            params: new Licensing.ParamValue[](0),
            parentLicenseId: licenseId_1_nonDeriv,
            ipaId: ipAssetId_3 // linked IP asset (owned by IPOrg 2)
        });
        vm.prank(ipOrgOwner2);
        licenseId_3_deriv = spg.createLicense(
            address(ipOrg2),
            lCreation,
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(licenseId_3_deriv, 3, "License ID should be 3");
        Licensing.LicenseData memory licenseData_3_derive = licenseRegistry
            .getLicenseData(licenseId_3_deriv);
        assertEq(
            uint8(licenseData_3_derive.status),
            uint8(Licensing.LicenseStatus.PendingLicensorApproval),
            "License should pending approval be if it's a derivative"
        );

        // Comment above on the first license applies here as well.
        vm.prank(ipOrgOwner2);
        spg.activateLicense(address(ipOrg2), licenseId_3_deriv);
        licenseData_3_derive = licenseRegistry
            .getLicenseData(licenseId_3_deriv); // refresh license data cached in memory
        assertEq(
            uint8(licenseData_3_derive.status),
            uint8(Licensing.LicenseStatus.Active),
            "License should be active"
        );

        ///
        /// =========================================
        ///            Link License NFTs (1)
        /// =========================================
        ///

        // Try to link license ID 1 (non-derivative) to Asset ID 3, which will fail
        // because Asset ID 3 is already linked to license ID 3 (derivative)
        vm.prank(address(licensingModule));
        vm.expectRevert(Errors.LicenseRegistry_LicenseAlreadyLinkedToIpa.selector);
        licenseRegistry.linkLnftToIpa(licenseId_1_nonDeriv, ipAssetId_3);

        // Link license ID 1 (non-derivative) to Asset ID 2 (Org 2, ID 2)
        vm.prank(address(licensingModule));
        vm.expectEmit(address(licenseRegistry));
        emit LicenseNftLinkedToIpa(licenseId_2_deriv, ipAssetId_2);
        licenseRegistry.linkLnftToIpa(licenseId_2_deriv, ipAssetId_2);
    }

    function _addRelationshipType(
        address ipOrg,
        LibRelationship.Relatables src,
        LibRelationship.Relatables dst,
        uint8 maxSrc
    ) internal {
        address caller = IIPOrg(ipOrg).owner();
        uint8[] memory allowedSrcs = new uint8[](0);
        uint8[] memory allowedDsts = new uint8[](0);
        if (ipOrg == address(0)) {
            caller = admin;
        } else {
            allowedSrcs = new uint8[](3);
            for (uint8 i = 0; i < maxSrc; i++) {
                allowedSrcs[i] = uint8(i);
            }
            allowedDsts = new uint8[](1);
            allowedDsts[0] = 1;
        }
        LibRelationship.RelatedElements memory allowedElements = LibRelationship
            .RelatedElements({ src: src, dst: dst });

        LibRelationship.AddRelationshipTypeParams
            memory params = LibRelationship.AddRelationshipTypeParams({
                relType: "TEST_RELATIONSHIP",
                ipOrg: ipOrg,
                allowedElements: allowedElements,
                allowedSrcs: allowedSrcs,
                allowedDsts: allowedDsts
            });

        // TODO test event
        vm.prank(caller);
        spg.addRelationshipType(params);
    }
}
