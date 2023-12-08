/* solhint-disable contract-name-camelcase, func-name-mixedcase, var-name-mixedcase */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IIPOrg } from "contracts/interfaces/ip-org/IIPOrg.sol";
import { IPOrg } from "contracts/ip-org/IPOrg.sol";
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { RegistrationModule } from "contracts/modules/registration/RegistrationModule.sol";
import { StoryProtocol } from "contracts/StoryProtocol.sol";
import { RelationshipModule } from "contracts/modules/relationships/RelationshipModule.sol";
import { LicensingModule } from "contracts/modules/licensing/LicensingModule.sol";
import { TokenGatedHook } from "contracts/hooks/TokenGatedHook.sol";
import { PolygonTokenHook } from "contracts/hooks/PolygonTokenHook.sol";
import { MockPolygonTokenClient } from "test/foundry/mocks/MockPolygonTokenClient.sol";
import { HookRegistry } from "contracts/modules/base/HookRegistry.sol";
import { HookResult, IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { Hook } from "contracts/lib/hooks/Hook.sol";
import { TokenGated } from "contracts/lib/hooks/TokenGated.sol";
import { PolygonToken } from "contracts/lib/hooks/PolygonToken.sol";
import { MockERC20 } from "test/foundry/mocks/MockERC20.sol";
import { MockERC721 } from "test/foundry/mocks/MockERC721.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { SPUMLParams } from "contracts/lib/modules/SPUMLParams.sol";
import { Registration } from "contracts/lib/modules/Registration.sol";
import { IE2ETest } from "test/foundry/interfaces/IE2ETest.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { BitMask } from "contracts/lib/BitMask.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";

contract E2ETest is IE2ETest, BaseTest {
    using ShortStrings for *;

    TokenGatedHook internal tokenGatedHook;
    PolygonTokenHook public polygonTokenHook;
    MockERC721 internal mockNFT;
    MockERC20 internal mockERC20;

    address internal ipOrgOwner1 = address(1234);
    address internal ipOrgOwner2 = address(4567);
    address internal ipOrgOwner3 = address(6789);
    address internal ipAssetOwner1 = address(6789);
    address internal ipAssetOwner2 = address(9876);
    address internal ipAssetOwner3 = address(8888);
    address internal ipAssetOwner4 = address(7777);
    address internal ipAssetOwner5 = address(6666);

    address internal ipOrg1;
    address internal ipOrg2;
    address internal ipOrg3;

    string internal FRAMEWORK_ID_DOGnCO = "test_framework_dog_and_co";
    string internal FRAMEWORK_ID_CATnCO = "test_framework_cat_and_co";
    string internal FRAMEWORK_ID_ORG3 = "test_framework_org3";

    uint256 internal mockPolygonTokenHookNonce;

    // variables defined here to avoid stack too deep error
    bytes[] internal hooksTransferIPAsset;
    uint256 internal licenseId_1_nonDeriv;
    uint256 internal licenseId_2_deriv;
    uint256 internal licenseId_3_deriv;
    uint256 internal licenseId_4_sub_deriv;
    uint256 internal ipAssetId_1;
    uint256 internal ipAssetId_2;
    uint256 internal ipAssetId_3;
    uint256 internal ipAssetId_4;
    uint256 internal ipAssetId_5;
    uint256 internal ipOrg1_AssetId_1;
    uint256 internal ipOrg1_AssetId_2;
    uint256 internal ipOrg2_AssetId_1;
    uint256 internal ipOrg2_AssetId_2;
    uint256 internal ipOrg3_AssetId_1;
    uint256 internal relIdProtocolLevel;
    string internal ipOrg1_baseUri = "http://iporg1.baseuri.url";
    string internal ipOrg2_baseUri = "http://iporg2.baseuri.url";
    string internal ipOrg3_baseUri = "http://iporg3.baseuri.url";
    string internal ipOrg1_contractUri = "http://iporg1.contracturi.url";
    string internal ipOrg2_contractUri = "http://iporg2.contracturi.url";
    string internal ipOrg3_contractUri = "http://iporg3.contracturi.url";

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
        bytes memory tokenGatedHookCode = abi.encodePacked(
            type(TokenGatedHook).creationCode,
            abi.encode(address(accessControl))
        );
        tokenGatedHook = TokenGatedHook(
            _deployHook(tokenGatedHookCode, Hook.SYNC_FLAG, 0)
        );
        moduleRegistry.registerProtocolHook(
            "TokenGatedHook",
            IHook(tokenGatedHook)
        );

        /// POLYGON_TOKEN_HOOK
        MockPolygonTokenClient mockPolygonTokenClient = new MockPolygonTokenClient();
        bytes memory polygonTokenHookCode = abi.encodePacked(
            type(PolygonTokenHook).creationCode,
            abi.encode(
                address(accessControl),
                mockPolygonTokenClient,
                address(this)
            )
        );
        polygonTokenHook = PolygonTokenHook(
            _deployHook(polygonTokenHookCode, Hook.ASYNC_FLAG, 0)
        );
        moduleRegistry.registerProtocolHook(
            "PolygonTokenHook",
            IHook(polygonTokenHook)
        );

        /// MOCK_ERC721, for regular token-gated hook
        /// In the example, ipAssetOwner1 and ipAssetOwner2 are owners of IPAs that are
        /// registered to an IPOrg (IPOrg 1) that uses TokenGated hook as pre-hook.
        mockNFT = new MockERC721();
        mockNFT.mint(ipAssetOwner1, 1);
        mockNFT.mint(ipAssetOwner2, 2);

        /// MOCK_ERC20, for Polygon token hook
        /// In the example, ipAssetOwner3 and ipAssetOwner4 are owners of IPAs that are
        /// registered to an IPOrg (IPOrg 2) that uses PolygonToken hook as pre-hook.
        mockERC20 = new MockERC20("MockERC20", "MERC20", 18);
        mockERC20.mint(2000);
        mockERC20.transfer(ipAssetOwner3, 1000);
        mockERC20.transfer(ipAssetOwner4, 1000);

        /// From above, you can also stack pre- or post-hooks!

        /// Setups
        _setUp_LicensingFramework();

        vm.label(ipOrgOwner1, "ipOrgOwner1");
        vm.label(ipOrgOwner2, "ipOrgOwner2");
    }

    function _setUp_LicensingFramework() internal {
        //
        /// Licensing Framework with ID: Dog & Co. (FRAMEWORK_ID_DOGnCO)
        //

        uint8[] memory enabledDerivativeIndice = new uint8[](2);
        enabledDerivativeIndice[0] = SPUMLParams.ALLOWED_WITH_APPROVAL_INDEX;
        // enabledDerivativeIndice[1] = SPUMLParams
        //     .ALLOWED_WITH_RECIPROCAL_LICENSE_INDEX;

        // Use 4 of SPUMLParams for Dog & Co.
        Licensing.ParamDefinition[]
            memory paramDefs = new Licensing.ParamDefinition[](4);
        ShortString[] memory derivativeChoices = new ShortString[](3);
        derivativeChoices[0] = SPUMLParams
            .ALLOWED_WITH_APPROVAL
            .toShortString();
        derivativeChoices[1] = SPUMLParams
            .ALLOWED_WITH_RECIPROCAL_LICENSE
            .toShortString();
        derivativeChoices[2] = SPUMLParams
            .ALLOWED_WITH_ATTRIBUTION
            .toShortString();

        paramDefs[0] = Licensing.ParamDefinition(
            SPUMLParams.CHANNELS_OF_DISTRIBUTION.toShortString(),
            Licensing.ParameterType.ShortStringArray,
            "",
            ""
        );
        paramDefs[1] = Licensing.ParamDefinition(
            SPUMLParams.ATTRIBUTION.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(true),
            ""
        );
        paramDefs[2] = Licensing.ParamDefinition(
            SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(true),
            ""
        );
        paramDefs[3] = Licensing.ParamDefinition({
            tag: SPUMLParams.DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            paramType: Licensing.ParameterType.MultipleChoice,
            // defaultValue: abi.encode(
            //     BitMask.convertToMask(enabledDerivativeIndice)
            // ),
            defaultValue: "",
            availableChoices: abi.encode(derivativeChoices)
        });

        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(
            Licensing.SetFramework({
                id: FRAMEWORK_ID_DOGnCO,
                textUrl: "text_url_dog_and_co",
                paramDefs: paramDefs
            })
        );

        //
        // Licensing Framework with ID: Cat & Co. (FRAMEWORK_ID_CATnCO)
        //

        paramDefs = new Licensing.ParamDefinition[](4);

        ShortString[] memory catColorChoices = new ShortString[](2);
        catColorChoices[0] = "cat_is_gold".toShortString();
        catColorChoices[1] = "cat_is_gray".toShortString();
        paramDefs[0] = Licensing.ParamDefinition({
            tag: "TEST_TAG_CAT_COLOR".toShortString(),
            paramType: Licensing.ParameterType.MultipleChoice,
            defaultValue: abi.encode(0),
            availableChoices: abi.encode(catColorChoices)
        });
        paramDefs[1] = Licensing.ParamDefinition({
            tag: "TEST_TAG_CAT_IS_CUTE".toShortString(),
            paramType: Licensing.ParameterType.Bool,
            defaultValue: abi.encode(true),
            availableChoices: ""
        });
        paramDefs[2] = Licensing.ParamDefinition(
            SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(true),
            ""
        );
        paramDefs[3] = Licensing.ParamDefinition({
            tag: SPUMLParams.DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            paramType: Licensing.ParameterType.MultipleChoice,
            defaultValue: "",
            availableChoices: abi.encode(derivativeChoices)
        });

        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(
            Licensing.SetFramework({
                id: FRAMEWORK_ID_CATnCO,
                textUrl: "text_url_cat_and_co",
                paramDefs: paramDefs
            })
        );

        //
        // Licensing Framework with ID: Org3 (FRAMEWORK_ID_ORG3)
        //

        paramDefs = new Licensing.ParamDefinition[](1);

        paramDefs[0] = Licensing.ParamDefinition(
            SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            Licensing.ParameterType.Bool,
            abi.encode(false),
            ""
        );

        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(
            Licensing.SetFramework({
                id: FRAMEWORK_ID_ORG3,
                textUrl: "text_url_org3",
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
        string[] memory ipAssetTypesScratchPad = new string[](3);
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
        ipOrg3 = spg.registerIpOrg(
            ipOrgOwner3,
            "IPOrgName3",
            "IPO3",
            ipAssetTypesShared
        );

        vm.label(ipOrg1, "IPOrg_1");
        vm.label(ipOrg2, "IPOrg_2");
        vm.label(ipOrg3, "IPOrg_3");

        // TODO: check for event `ModuleConfigured`
        vm.prank(ipOrgOwner1);
        spg.addIPAssetTypes(ipOrg1, ipAssetTypesOnly1);

        vm.prank(ipOrgOwner2);
        spg.addIPAssetTypes(ipOrg2, ipAssetTypesOnly2);

        ipAssetTypesScratchPad = registrationModule.getIpOrgAssetTypes(ipOrg3);
        for (uint256 i = 0; i < ipAssetTypesScratchPad.length; i++) {
            assertEq(
                ipAssetTypesScratchPad[i],
                ipAssetTypesShared[i],
                "ipAssetTypesScratchPad[i] should match ipAssetTypesShared[i]"
            );
        }

        ipAssetTypesScratchPad = registrationModule.getIpOrgAssetTypes(ipOrg2);
        assertEq(
            ipAssetTypesScratchPad.length,
            ipAssetTypesShared.length + ipAssetTypesOnly1.length,
            "length should match"
        );

        ///
        /// =========================================
        ///         Configure IPOrg modules
        /// =========================================
        ///

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

        vm.prank(ipOrgOwner3);
        spg.setMetadata(ipOrg3, ipOrg3_baseUri, ipOrg3_contractUri);

        ///
        /// =========================================
        ///   Register hooks via RegistrationModule
        /// =========================================
        ///

        _registerHooksForIPOrgs();

        ///
        /// =========================================
        ///           Add Relationship types
        /// =========================================
        ///

        LibRelationship.RelatedElements memory allowedElements = LibRelationship
            .RelatedElements({
                src: LibRelationship.Relatables.Address,
                dst: LibRelationship.Relatables.Address
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
            src: LibRelationship.Relatables.Address,
            dst: LibRelationship.Relatables.Address
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
                srcId: 1, // source, global asset id
                dstAddress: ipOrg1,
                dstId: 2 // destination, global asset id
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
        ///   Configure IPOrg's org-wide Licensing
        /// =========================================
        ///

        //
        // NOTE: For each ipOrg, we set IPOrg-wide Licensing terms that get applied to any Licenses under that IPOrg.
        //       Licenses can modify terms within its IPOrg's assigned Licensing framework, as long as those terms
        //       aren't specified in IPOrg-wide Licensing terms.
        //       In other words, you must use IPOrg-wide Licensing terms and modify what's untouched.
        //

        //
        // Configure licensing for IPOrg1 (Dog & Co.)
        // Enforce these license terms to all Licenses under IPOrg1.
        //

        Licensing.ParamValue[] memory lParams = new Licensing.ParamValue[](3);
        ShortString[] memory channel_distribution = new ShortString[](2);

        channel_distribution[0] = "dog loves hoomans".toShortString();
        channel_distribution[1] = "dog conquers world".toShortString();

        uint8[] memory enabledDerivativeIndice = new uint8[](1);
        enabledDerivativeIndice[0] = SPUMLParams.ALLOWED_WITH_APPROVAL_INDEX;
        // enabledDerivativeIndice[1] = SPUMLParams
        //     .ALLOWED_WITH_ATTRIBUTION_INDEX;

        // Use the list of terms from SPUMLParams
        lParams = new Licensing.ParamValue[](4);
        lParams[0] = Licensing.ParamValue({
            tag: SPUMLParams.CHANNELS_OF_DISTRIBUTION.toShortString(),
            value: abi.encode(channel_distribution)
        });
        lParams[1] = Licensing.ParamValue({
            tag: SPUMLParams.ATTRIBUTION.toShortString(),
            value: abi.encode(true) // unset
        });
        lParams[2] = Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            value: abi.encode(true)
        });
        lParams[3] = Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            // (active) derivative options are set via bitmask
            value: abi.encode(BitMask.convertToMask(enabledDerivativeIndice))
        });

        Licensing.LicensingConfig memory licensingConfig = Licensing
            .LicensingConfig({
                frameworkId: FRAMEWORK_ID_DOGnCO,
                params: lParams,
                // licensor: Licensing.LicensorConfig.Source
                licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
            });

        // TODO: event check for `configureIpOrgLicensing`
        vm.startPrank(ipOrgOwner1);
        spg.configureIpOrgLicensing(ipOrg1, licensingConfig);
        // Two `configureIpOrgLicensing`s are commented out since right now, we allow
        // `configureIpOrgLicensing` to be called only once per IPOrg.
        // spg.configureIpOrgLicensing(ipOrg2, licensingConfig); // this should get overwritten by Unset
        // spg.configureIpOrgLicensing(ipOrg2, Licensing.LicensingConfig({
        //     frameworkId: FRAMEWORK_ID_DOGnCO,
        //     params: lParams,
        //     licensor: Licensing.LicensorConfig.Unset
        // }));
        vm.stopPrank();

        //
        // Configure licensing for IPOrg2 (Cat & Co.).
        // Enforce these license terms to all Licenses under IPOrg2.
        // => TEST_TAG_CAT_COLOR = 1 (cat_is_gray)
        // => TEST_TAG_CAT_IS_CUTE = true
        //

        lParams = new Licensing.ParamValue[](2);
        lParams[0] = Licensing.ParamValue({
            tag: "TEST_TAG_CAT_COLOR".toShortString(),
            value: abi.encode(1) // BitMask, or just 1 to indicate index 1
        });
        lParams[1] = Licensing.ParamValue({
            tag: "TEST_TAG_CAT_IS_CUTE".toShortString(),
            value: abi.encode(true)
        });

        licensingConfig = Licensing.LicensingConfig({
            frameworkId: FRAMEWORK_ID_CATnCO,
            params: lParams,
            // licensor: Licensing.LicensorConfig.Source
            licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
        });

        // TODO: event check for `configureIpOrgLicensing`
        vm.prank(ipOrgOwner2);
        spg.configureIpOrgLicensing(ipOrg2, licensingConfig);

        //
        // Configure licensing for IPOrg3.
        // Enforce these license terms to all Licenses under IPOrg3.
        // => DERIVATIVES_ALLOWED = false
        //

        lParams = new Licensing.ParamValue[](1);
        lParams[0] = Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            value: abi.encode(false)
        });

        licensingConfig = Licensing.LicensingConfig({
            frameworkId: FRAMEWORK_ID_ORG3,
            params: lParams,
            licensor: Licensing.LicensorConfig.Source
            // licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
        });

        vm.prank(ipOrgOwner3);
        spg.configureIpOrgLicensing(ipOrg3, licensingConfig);

        //
        // Configure
        //

        ///
        /// =========================================
        ///             Register IP Assets
        /// =========================================
        ///

        _registerIpAssets();

        ///
        /// =========================================
        ///            IP Assets Transfers
        /// =========================================
        ///

        vm.expectEmit(address(registrationModule));
        emit IPAssetTransferred(1, ipOrg1, 1, ipAssetOwner1, ipAssetOwner2);
        vm.prank(ipAssetOwner1);
        spg.transferIPAsset(
            ipOrg1,
            ipAssetOwner1,
            ipAssetOwner2,
            1, // global asset id
            // IPOrg1 has no pre-hooks set for action `TRANSFER_IP_ASSET`, so we pass in empty params
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(
            registry.ipAssetOwner(1),
            ipAssetOwner2,
            "owner should be ipAssetOwner2 after transferIPAsset"
        );

        // Transfer back, `ipAssetOwner2` also has enough balance of mockNFT
        vm.prank(ipAssetOwner2);
        spg.transferIPAsset(
            ipOrg1,
            ipAssetOwner2,
            ipAssetOwner1,
            1, // global asset id
            // IPOrg1 has no pre-hooks set for action `TRANSFER_IP_ASSET`, so we pass in empty params
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(
            registry.ipAssetOwner(1),
            ipAssetOwner1,
            "owner should be ipAssetOwner1 after transferIPAsset"
        );

        // // Since we've configured PolygonToken hook for IPOrg2 on `TRANSFER_IP_ASSET` action,
        // // it will get triggered here. The hook will check if the sender has enough token
        // // balance (in this case, mockERC20) to transfer the IP asset. If not, it will revert.
        // hooksTransferIPAsset = new bytes[](1);
        // hooksTransferIPAsset[0] = abi.encode(ipAssetOwner4);

        // // vm.expectEmit(address(registrationModule));
        // // emit IPAssetTransferred(1, ipOrg1, 1, ipAssetOwner1, ipAssetOwner2);
        // vm.prank(ipAssetOwner4);
        // spg.transferIPAsset(
        //     ipOrg2,
        //     ipAssetOwner4,
        //     ipAssetOwner3,
        //     4, // asset id
        //     // IPOrg2 has 1 pre-hook set for action `TRANSFER_IP_ASSET`
        //     hooksTransferIPAsset,
        //     new bytes[](0)
        // );

        // _triggerMockPolygonTokenHook(ipAssetOwner4);

        ///
        /// =========================================
        ///          Random IP Asset actions
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
        // NOTE You can only add/use ParamValues that aren't used by the license's IPOrg,
        //      since IPOrg's license terms are enforced to all Licenses under that IPOrg.
        //

        //
        // Create a license for Asset ID 1 (Org 1, ID 1)
        // Use SPUMLParams license framework, which is attached to Org 2 (cat & co.)
        //

        // Only inherit IPOrg's org-wide licensing terms, don't set any params
        Licensing.LicenseCreation memory lCreation = Licensing.LicenseCreation({
            params: new Licensing.ParamValue[](0),
            parentLicenseId: 0, // no parent
            ipaId: ipAssetId_1
        });
        vm.prank(ipOrgOwner1);
        licenseId_1_nonDeriv = spg.createLicense(
            address(ipOrg1),
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
            "License 1 (Org 1) should active on creation + not a derivative"
        );

        assertEq(
            licenseData_1_nonDeriv.derivativesAllowed,
            true,
            "License 1 (Org 1) should allow derivatives"
        );
        assertEq(
            licenseData_1_nonDeriv.isReciprocal,
            false,
            "License 1 (Org 1) should NOT be reciprocal"
        );
        assertEq(
            licenseData_1_nonDeriv.derivativeNeedsApproval,
            true,
            "License 1 (Org 1) should approve derivatives"
        );
        assertEq(
            licenseData_1_nonDeriv.ipaId,
            ipAssetId_1,
            "License 1 (Org 1)'s linked IPA ID should be 1"
        );
        assertEq(
            licenseData_1_nonDeriv.parentLicenseId,
            0,
            "License 1 (Org 1) should have no parent license"
        );

        // Since this is a license without a parent license, the license should be activated immediately on
        // `createLicense`. This is already checked about via status == LicenseStatus.Active, but again checked here.
        // This is just a test that expects revert.
        vm.expectRevert(
            Errors.LicenseRegistry_LicenseNotPendingApproval.selector
        );
        vm.prank(ipOrgOwner1);
        spg.activateLicense(address(ipOrg1), licenseId_1_nonDeriv);

        //
        // Create two more licenses for Asset ID 3 (Org 2, ID 1), this time with a parent license
        // (licenseId_1_nonDeriv created above), so this is a sub-license.
        //
        // Since `licenseId_1_nonDeriv` is reciprocal (as we've configured for SPUMLParams),
        // the two sub-licenses can't modify the params, ie. they inherit the parent's params.
        //
        // First sub-license is created without a linked IP asset, second sub-license is created with a linked IP asset.
        // Both sub-licenses will be pending approval on creation — parent license has specified in its license terms.
        // They will need to get approved by the parent license's licensor.
        //
        // Third sub-sub-license is derived from the second sub-license, and created without a linked IP asset.
        // This license will be approved immediately on creation, as the second sub-license didn't specify the
        // "require approval from derivatives" (ALLOWED_WITH_APPROVAL) in its terms.
        //
        //

        //
        // First once should have no IP asset linked on creation.
        // This license does NOT allow derivatives.
        //

        lParams = new Licensing.ParamValue[](3);
        // allow channel of distribution
        lParams[0] = Licensing.ParamValue({
            tag: SPUMLParams.CHANNELS_OF_DISTRIBUTION.toShortString(),
            value: abi.encode(true)
        });
        // require attribution
        lParams[1] = Licensing.ParamValue({
            tag: SPUMLParams.ATTRIBUTION.toShortString(),
            value: abi.encode(true)
        });
        // disable derivatives
        lParams[2] = Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            value: abi.encode(false)
        });

        lCreation = Licensing.LicenseCreation({
            params: lParams,
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
        Licensing.LicenseData memory licenseData_2_deriv = licenseRegistry
            .getLicenseData(licenseId_2_deriv);
        assertEq(
            uint8(licenseData_2_deriv.status),
            uint8(Licensing.LicenseStatus.PendingLicensorApproval),
            "License 2 (Org 1) should be pending approval on creation"
        );

        vm.prank(ipOrgOwner2);
        spg.activateLicense(address(ipOrg2), licenseId_2_deriv);
        licenseData_2_deriv = licenseRegistry.getLicenseData(licenseId_2_deriv); // refresh license data in mem
        assertEq(
            uint8(licenseData_2_deriv.status),
            uint8(Licensing.LicenseStatus.Active),
            "License 2 (Org 1) should be active"
        );
        assertEq(
            licenseData_2_deriv.derivativesAllowed,
            false,
            "License 2 (Org 1) should NOT allow derivatives"
        );
        assertEq(
            licenseData_2_deriv.isReciprocal,
            false,
            "License 2 (Org 1) should NOT be reciprocal"
        );
        assertEq(
            licenseData_2_deriv.derivativeNeedsApproval,
            false,
            "License 2 (Org 1) should not need to approve derivatives"
        );
        assertEq(
            licenseData_2_deriv.ipaId,
            0,
            "License 2 (Org 1) should not be linked to IPA"
        );
        assertEq(
            licenseData_2_deriv.parentLicenseId,
            licenseId_1_nonDeriv,
            "License 2 (Org 1) should have parent license"
        );

        //
        // Second one should have an IP asset linked on creation
        // This license allows derivatives.
        //

        lParams = new Licensing.ParamValue[](2);
        // allow derivatives without approval, but require reciprocal license
        enabledDerivativeIndice[0] = SPUMLParams
            .ALLOWED_WITH_RECIPROCAL_LICENSE_INDEX;

        // derivatives allowed
        lParams[0] = Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED.toShortString(),
            value: abi.encode(true)
        });
        // derivative options => derivatives must be of reciprocal
        lParams[1] = Licensing.ParamValue({
            tag: SPUMLParams.DERIVATIVES_ALLOWED_OPTIONS.toShortString(),
            value: abi.encode(BitMask.convertToMask(enabledDerivativeIndice))
        });

        lCreation = Licensing.LicenseCreation({
            params: lParams,
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
        Licensing.LicenseData memory licenseData_3_deriv = licenseRegistry
            .getLicenseData(licenseId_3_deriv);
        assertEq(
            uint8(licenseData_3_deriv.status),
            uint8(Licensing.LicenseStatus.PendingLicensorApproval),
            "License 3 (Org 2) should be pending approval on creation"
        );

        // Comment above on the first license applies here as well.
        vm.prank(ipOrgOwner2);
        spg.activateLicense(address(ipOrg2), licenseId_3_deriv);
        licenseData_3_deriv = licenseRegistry.getLicenseData(licenseId_3_deriv); // refresh license data
        assertEq(
            uint8(licenseData_3_deriv.status),
            uint8(Licensing.LicenseStatus.Active),
            "License 3 (Org 2) should be active"
        );
        assertEq(
            licenseData_3_deriv.derivativesAllowed,
            true,
            "License 3 (Org 2) should allow derivatives"
        );
        assertEq(
            licenseData_3_deriv.isReciprocal,
            true,
            "License 3 (Org 2) should be reciprocal"
        );
        assertEq(
            licenseData_3_deriv.derivativeNeedsApproval,
            false,
            "License 3 (Org 2) should allow derivatives without approval"
        );
        assertEq(
            licenseData_3_deriv.ipaId,
            ipAssetId_3,
            "License 3 (Org 2) should be linked to IPA"
        );
        assertEq(
            licenseData_3_deriv.parentLicenseId,
            licenseId_1_nonDeriv,
            "License 3 (Org 2) should have parent license"
        );

        //
        // Check that license 2 (Org 1) doesn't allow derivative
        //

        lCreation = Licensing.LicenseCreation({
            params: new Licensing.ParamValue[](0), // no licensing params
            parentLicenseId: licenseId_2_deriv, // License ID 2 DOES NOT ALLOW DERIVATIVES
            ipaId: 0 // no linked IPA
        });
        vm.prank(ipOrgOwner3);
        vm.expectRevert(Errors.LicensingModule_DerivativeNotAllowed.selector);
        licenseId_4_sub_deriv = spg.createLicense(
            address(ipOrg3),
            lCreation,
            new bytes[](0),
            new bytes[](0)
        );

        //
        // Create another license that has parent license (licenseId_4_sub_deriv), which is also a sublicense.
        //

        lCreation = Licensing.LicenseCreation({
            params: new Licensing.ParamValue[](0), // no licensing params
            parentLicenseId: licenseId_3_deriv, // License 3 allows derivative without approval
            ipaId: 0 // no linked IPA
        });
        vm.prank(ipOrgOwner3);
        licenseId_4_sub_deriv = spg.createLicense(
            address(ipOrg3),
            lCreation,
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(licenseId_4_sub_deriv, 4, "License ID should be 4");
        Licensing.LicenseData memory licenseData_4_sub_deriv = licenseRegistry
            .getLicenseData(licenseId_4_sub_deriv);
        assertEq(
            uint8(licenseData_4_sub_deriv.status),
            uint8(Licensing.LicenseStatus.Active),
            "License 4 (Org 3) should active on creation"
        );
        assertEq(
            licenseData_4_sub_deriv.derivativesAllowed,
            true,
            "License 4 (Org 3) should allow derivatives (parent is reciprocal, parent allows derivative)"
        );
        assertEq(
            licenseData_4_sub_deriv.isReciprocal,
            true,
            "License 4 (Org 3) should be reciprocal (parent is reciprocal, parent allows derivative)"
        );
        assertEq(
            licenseData_4_sub_deriv.derivativeNeedsApproval,
            false,
            "License 4 (Org 3) should not need to approve derivative (parent is reciprocal)"
        );
        assertEq(
            licenseData_4_sub_deriv.ipaId,
            0,
            "License 4 (Org 3) should not be linked to IPA"
        );
        assertEq(
            licenseData_4_sub_deriv.parentLicenseId,
            licenseId_3_deriv,
            "License 4 (Org 3) should have parent license"
        );

        ///
        /// =========================================
        ///            Link License NFTs (1)
        /// =========================================
        ///

        // Try to link license ID 1 (non-derivative) to Asset ID 3, which will fail
        // because Asset ID 3 is already linked to license ID 3 (derivative)
        vm.prank(address(licensingModule));
        vm.expectRevert(
            Errors.LicenseRegistry_LicenseAlreadyLinkedToIpa.selector
        );
        // // One way to link LNFT to IPA
        spg.linkLnftToIpa(ipOrg2, licenseId_1_nonDeriv, ipAssetId_3);

        // Link license ID 1 (non-derivative) to Asset ID 2 (Org 2, ID 2)
        vm.prank(address(licensingModule));
        vm.expectEmit(address(licenseRegistry));
        emit LicenseNftLinkedToIpa(licenseId_2_deriv, ipAssetId_2);
        // Another way to link LNFT to IPA
        licenseRegistry.linkLnftToIpa(licenseId_2_deriv, ipAssetId_2);

        ///
        ///
        /// Register IP Asset & Link to LNFT at the same time
        ///
        ///

        string memory ipAssetMediaUrl = "https://arweave.net/music3";
        Registration.RegisterIPAssetParams memory ipAssetData = Registration.RegisterIPAssetParams({
            owner: ipAssetOwner5,
            ipOrgAssetType: 1,
            name: "Music IPA 3",
            hash: 0x558b44f88e5959cec9c7836078a53ff4d6432142a9d5caa6f3a6eb7c83933399,
            mediaUrl: ipAssetMediaUrl
        });

        vm.prank(ipAssetOwner5);
        vm.expectRevert(Errors.LicenseRegistry_LicenseAlreadyLinkedToIpa.selector);
        (uint256 ipAssetId_6, uint256 ipOrg3_AssetId_2) = spg.registerIPAsset(
            ipOrg3,
            ipAssetData,
            licenseId_3_deriv,
            new bytes[](0), // no pre-hook
            new bytes[](0) // no post-hook
        );

        vm.prank(ipAssetOwner5);
        (ipAssetId_6, ipOrg3_AssetId_2) = spg.registerIPAsset(
            ipOrg3,
            ipAssetData,
            licenseId_4_sub_deriv,
            new bytes[](0), // no pre-hook
            new bytes[](0) // no post-hook
        );
        assertEq(ipAssetId_6, 6, "ipAssetId_6 should be 6");
        assertEq(ipOrg3_AssetId_2, 2, "ipOrg3_AssetId_2 should be 2");
        assertEq(
            IPOrg(ipOrg3).ipAssetId(ipOrg3_AssetId_2),
            ipAssetId_6,
            "ipOrg3_AssetId_2 should be global ID 6"
        );
        assertEq(
            IPOrg(ipOrg3).tokenURI(ipOrg3_AssetId_2),
            ipAssetMediaUrl,
            string.concat("tokenURI should be ", ipAssetMediaUrl)
        );
    }

    ///
    /// =========================================
    ///
    ///         Register Hooks for IPOrgs
    ///
    /// =========================================
    ///

    function _registerHooksForIPOrgs() internal {
        // Add token gated hook & polygon token gated hook
        // Specify the configuration for the token gated hook, ie. which token to use
        address[] memory hooks = new address[](1);
        bytes[] memory hooksConfig = new bytes[](1);

        // TokenGated hook that uses MockERC721
        TokenGated.Config memory tokenGatedConfig = TokenGated.Config({
            tokenAddress: address(mockNFT)
        });

        // PolygonToken hook that uses MockERC20
        PolygonToken.Config memory polygonTokenConfig = PolygonToken.Config({
            tokenAddress: address(mockERC20),
            balanceThreshold: 1
        });

        //
        // Register TokenGated hook for IPOrg1 in pre-action hooks.
        // This hook is triggered on `REGISTER_IP_ASSET` action.
        // => this means user needs to hold some tokens on Polygon to register IPAs.
        //
        hooks[0] = address(tokenGatedHook);
        hooksConfig[0] = abi.encode(tokenGatedConfig);
        vm.prank(ipOrgOwner1);
        vm.expectEmit(address(registrationModule));
        emit HooksRegistered(
            HookRegistry.HookType.PreAction,
            keccak256(
                abi.encode(
                    address(ipOrg1),
                    Registration.REGISTER_IP_ASSET,
                    "REGISTRATION"
                )
            ),
            hooks
        );
        RegistrationModule(registrationModule).registerHooks(
            HookRegistry.HookType.PreAction,
            IIPOrg(ipOrg1),
            hooks,
            hooksConfig,
            abi.encode(Registration.REGISTER_IP_ASSET)
        );

        //
        // Register PolygonToken hook for IPOrg2 in pre-action hook
        // This hook is triggered on both `REGISTER_IP_ASSET` and `TRANSFER_IP_ASSET` action.
        // => this means user needs to hold some tokens on Polygon to register & transfer IPAs.
        //
        hooks[0] = address(polygonTokenHook);
        hooksConfig[0] = abi.encode(polygonTokenConfig);
        vm.prank(ipOrgOwner2);
        vm.expectEmit(address(registrationModule));
        emit HooksRegistered(
            HookRegistry.HookType.PreAction,
            keccak256(
                abi.encode(
                    address(ipOrg2),
                    Registration.TRANSFER_IP_ASSET,
                    "REGISTRATION"
                )
            ),
            hooks
        );
        RegistrationModule(registrationModule).registerHooks(
            HookRegistry.HookType.PreAction,
            IIPOrg(ipOrg2),
            hooks,
            hooksConfig,
            abi.encode(Registration.TRANSFER_IP_ASSET)
        );

        vm.prank(ipOrgOwner2);
        vm.expectEmit(address(registrationModule));
        emit HooksRegistered(
            HookRegistry.HookType.PreAction,
            keccak256(
                abi.encode(
                    address(ipOrg2),
                    Registration.REGISTER_IP_ASSET,
                    "REGISTRATION"
                )
            ),
            hooks
        );
        RegistrationModule(registrationModule).registerHooks(
            HookRegistry.HookType.PreAction,
            IIPOrg(ipOrg2),
            hooks,
            hooksConfig,
            abi.encode(Registration.REGISTER_IP_ASSET)
        );
    }

    ///
    /// =========================================
    ///
    ///       Register IP Assets for IPOrgs
    ///
    /// =========================================
    ///

    function _registerIpAssets() internal {
        //
        // Asset ID 1 (Org 1, ID 1)
        //

        string memory ipAssetMediaUrl = "https://arweave.net/character";
        bytes[] memory preHooksData = new bytes[](0);

        Registration.RegisterIPAssetParams memory ipAssetData = Registration
            .RegisterIPAssetParams({
                owner: ipAssetOwner1,
                ipOrgAssetType: 0,
                name: "Character IPA",
                hash: 0x558b44f88e5959cec9c7836078a53ff4d6432142a9d5caa6f3a6eb7c83930000,
                mediaUrl: ipAssetMediaUrl
            });

        // hooks
        TokenGated.Params memory tokenGatedHookData = TokenGated.Params({
            tokenOwner: ipAssetOwner1
        });
        preHooksData = new bytes[](1);
        preHooksData[0] = abi.encode(tokenGatedHookData);

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
            ipAssetData,
            0,
            preHooksData,
            new bytes[](0)
        );
        assertEq(ipAssetId_1, 1, "ipAssetId_1 should be 1");
        assertEq(ipOrg1_AssetId_1, 1, "ipOrg1_AssetId_1 should be 1");
        assertEq(
            IPOrg(ipOrg1).ipAssetId(ipOrg1_AssetId_1),
            ipAssetId_1,
            "ipOrg1_AssetId_1 should be global ID 1"
        );
        assertEq(
            IPOrg(ipOrg1).tokenURI(ipOrg1_AssetId_1),
            ipAssetMediaUrl,
            string.concat("tokenURI should be ", ipAssetMediaUrl)
        );

        //
        // Asset ID 2 (Org 1, ID 2)
        //

        ipAssetMediaUrl = "https://arweave.net/story";
        ipAssetData = Registration.RegisterIPAssetParams({
            owner: ipAssetOwner2,
            ipOrgAssetType: 1,
            name: "Story IPA",
            hash: 0x558b44f88e5959cec9c7836078a53ff4d6432142a9d5caa6f3a6eb7c83931166,
            mediaUrl: ipAssetMediaUrl
        });
        tokenGatedHookData = TokenGated.Params({ tokenOwner: ipAssetOwner2 });
        preHooksData = new bytes[](1);
        preHooksData[0] = abi.encode(tokenGatedHookData);
        vm.prank(ipAssetOwner2);
        (ipAssetId_2, ipOrg1_AssetId_2) = spg.registerIPAsset(
            ipOrg1,
            ipAssetData,
            0,
            preHooksData,
            new bytes[](0)
        );
        assertEq(ipAssetId_2, 2, "ipAssetId_2 should be 2");
        assertEq(ipOrg1_AssetId_2, 2, "ipOrg1_AssetId_2 should be 2");
        assertEq(
            IPOrg(ipOrg1).ipAssetId(ipOrg1_AssetId_2),
            ipAssetId_2,
            "ipOrg1_AssetId_2 should be global ID 2"
        );
        assertEq(
            IPOrg(ipOrg1).tokenURI(ipOrg1_AssetId_2),
            ipAssetMediaUrl,
            string.concat("tokenURI should be ", ipAssetMediaUrl)
        );

        //
        // Asset ID 3 (Org 2, ID 1)
        //

        PolygonToken.Params memory polygonTokenHookParams = PolygonToken
            .Params({ tokenOwnerAddress: ipAssetOwner3 });
        preHooksData = new bytes[](1);
        preHooksData[0] = abi.encode(polygonTokenHookParams);

        ipAssetMediaUrl = "https://arweave.net/story2";
        ipAssetData = Registration.RegisterIPAssetParams({
            owner: ipAssetOwner3,
            ipOrgAssetType: 1,
            name: "Story IPA 2",
            hash: 0x558b44f88e5959cec9c7836078a53ff4d6432142a9d5caa6f3a6eb7c83933377,
            mediaUrl: ipAssetMediaUrl
        });
        vm.prank(ipAssetOwner3);
        // TODO: also check for event `AsyncHookExecuted`
        vm.expectEmit(address(registrationModule));
        emit RequestPending(ipAssetOwner3);
        // vm.expectEmit(address(polygonTokenHook));
        // emit PolygonTokenBalanceRequest(
        //     _getMockPolygonTokenHookReqId(),
        //     address(registrationModule),
        //     address(mockERC20),
        //     address(ipAssetOwner3),
        //     address(polygonTokenHook),
        //     polygonTokenHook.handleCallback.selector
        // );
        spg.registerIPAsset(
            ipOrg2,
            ipAssetData,
            0, // no license
            preHooksData, // pre-hook params: PolygonToken
            new bytes[](0) // no post-hook
        );

        // Registering IPAsset with Async hook will not return the proper Global Asset ID & Org's Asset ID
        // So we manually have to find the Global Asset ID & Org's Asset ID
        ipAssetId_3 = 3;
        ipOrg2_AssetId_1 = 1;

        // IPOrg2 has Polygon Token hook as pre-hook action for
        // IPA Registration. So we mock the callback from Polygon Token hook.
        _triggerMockPolygonTokenHook(ipAssetOwner3);

        assertEq(ipAssetId_3, 3, "ipAssetId_3 should be 3");
        assertEq(ipOrg2_AssetId_1, 1, "ipOrg2_AssetId_1 should be 1");
        assertEq(
            IPOrg(ipOrg2).ipAssetId(ipOrg2_AssetId_1),
            ipAssetId_3,
            "ipOrg2_AssetId_1 should be global ID 3"
        );
        assertEq(
            IPOrg(ipOrg2).tokenURI(ipOrg2_AssetId_1),
            ipAssetMediaUrl,
            string.concat("tokenURI should be ", ipAssetMediaUrl)
        );

        //
        // Asset ID 4 (Org 2, ID 2)
        //

        polygonTokenHookParams = PolygonToken.Params({
            tokenOwnerAddress: ipAssetOwner4
        });
        preHooksData = new bytes[](1);
        preHooksData[0] = abi.encode(polygonTokenHookParams);

        ipAssetMediaUrl = "https://arweave.net/music1";
        ipAssetData = Registration.RegisterIPAssetParams({
            owner: ipAssetOwner4,
            ipOrgAssetType: 1,
            name: "Music IPA",
            hash: 0x558b44f88e5959cec9c7836078a53ff4d6432142a9d5caa6f3a6eb7c83933388,
            mediaUrl: ipAssetMediaUrl
        });
        vm.prank(ipAssetOwner4);
        // TODO: also check for event `AsyncHookExecuted`
        vm.expectEmit(address(registrationModule));
        emit RequestPending(ipAssetOwner4);
        // vm.expectEmit(address(polygonTokenHook));
        // emit PolygonTokenBalanceRequest(
        //     _getMockPolygonTokenHookReqId(),
        //     address(registrationModule),
        //     address(mockERC20),
        //     address(ipAssetOwner4),
        //     address(polygonTokenHook),
        //     polygonTokenHook.handleCallback.selector
        // );
        spg.registerIPAsset(
            ipOrg2,
            ipAssetData,
            0, // no license
            preHooksData, // pre-hook params: PolygonToken
            new bytes[](0) // no post-hook
        );

        // Registering IPAsset with Async hook will not return the proper Global Asset ID & Org's Asset ID
        // So we manually have to find the Global Asset ID & Org's Asset ID
        ipAssetId_4 = 4;
        ipOrg2_AssetId_2 = 2;

        // IPOrg2 has Polygon Token hook as pre-hook action for
        // IPA Registration. So we mock the callback from Polygon Token hook.
        _triggerMockPolygonTokenHook(ipAssetOwner4);

        assertEq(ipAssetId_4, 4, "ipAssetId_4 should be 4");
        assertEq(ipOrg2_AssetId_2, 2, "ipOrg2_AssetId_2 should be 2");
        assertEq(
            IPOrg(ipOrg2).ipAssetId(ipOrg2_AssetId_2),
            ipAssetId_4,
            "ipOrg2_AssetId_2 should be global ID 4"
        );
        assertEq(
            IPOrg(ipOrg2).tokenURI(ipOrg2_AssetId_2),
            ipAssetMediaUrl,
            string.concat("tokenURI should be ", ipAssetMediaUrl)
        );

        //
        // Asset ID 5 (Org 3, ID 1)
        //

        ipAssetMediaUrl = "https://arweave.net/music2";
        ipAssetData = Registration.RegisterIPAssetParams({
            owner: ipAssetOwner5,
            ipOrgAssetType: 1,
            name: "Music IPA 2",
            hash: 0x558b44f88e5959cec9c7836078a53ff4d6432142a9d5caa6f3a6eb7c83933399,
            mediaUrl: ipAssetMediaUrl
        });
        vm.prank(ipAssetOwner5);
        (ipAssetId_5, ipOrg3_AssetId_1) = spg.registerIPAsset(
            ipOrg3,
            ipAssetData,
            0, // no license
            new bytes[](0), // no pre-hook
            new bytes[](0) // no post-hook
        );
        assertEq(ipAssetId_5, 5, "ipAssetId_5 should be 5");
        assertEq(ipOrg3_AssetId_1, 1, "ipOrg3_AssetId_1 should be 1");
        assertEq(
            IPOrg(ipOrg3).ipAssetId(ipOrg3_AssetId_1),
            ipAssetId_5,
            "ipOrg3_AssetId_1 should be global ID 5"
        );
        assertEq(
            IPOrg(ipOrg3).tokenURI(ipOrg3_AssetId_1),
            ipAssetMediaUrl,
            string.concat("tokenURI should be ", ipAssetMediaUrl)
        );
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

    function _triggerMockPolygonTokenHook(address caller_) internal {
        bytes32 polygonHookReqId = _getMockPolygonTokenHookReqId();
        mockPolygonTokenHookNonce++;

        // vm.expectEmit(address(registrationModule));
        // emit RequestCompleted(address(caller_));
        // vm.expectEmit(address(polygonTokenHook));
        // emit AsyncHookCalledBack(
        //     address(polygonTokenHook),
        //     address(registrationModule),
        //     polygonHookReqId,
        //     abi.encode(mockERC20.balanceOf(address(caller_)))
        // );
        polygonTokenHook.handleCallback(
            polygonHookReqId,
            mockERC20.balanceOf(address(caller_))
        );
    }

    function _getMockPolygonTokenHookReqId() internal returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(polygonTokenHook),
                    uint256(mockPolygonTokenHookNonce)
                )
            );
    }
}
