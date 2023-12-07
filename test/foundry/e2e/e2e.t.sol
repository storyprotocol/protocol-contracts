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
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract E2ETest is IE2ETest, BaseTest {
    using ShortStrings for *;

    address public tokenGatedHook;
    MockERC721 public mockNFT;

    // create 3 roles: protocol admin, ip org owner, ip asset owner
    address public ipOrgOwner1 = address(1234);
    address public ipOrgOwner2 = address(4567);
    address public ipAssetOwner1 = address(6789);
    address public ipAssetOwner2 = address(9876);
    address public ipAssetOwner3 = address(9876);

    address public ipOrg1;
    address public ipOrg2;

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

        // framework
        Licensing.ParamDefinition[]
            memory fParams = new Licensing.ParamDefinition[](3);
        fParams[0] = Licensing.ParamDefinition({
            tag: "TEST_TAG_1".toShortString(),
            paramType: Licensing.ParameterType.Bool
        });
        fParams[1] = Licensing.ParamDefinition({
            tag: "TEST_TAG_2".toShortString(),
            paramType: Licensing.ParameterType.Number
        });
        fParams[2] = Licensing.ParamDefinition({
            tag: "TEST_TAG_3".toShortString(),
            paramType: Licensing.ParameterType.MultipleChoice
        });
        Licensing.SetFramework memory framework = Licensing.SetFramework({
            id: "test_framework",
            textUrl: "text_url",
            paramDefs: fParams
        });
        vm.prank(licensingManager);
        licensingFrameworkRepo.addFramework(framework);
    }

    function test_e2e() public {
        //
        // IPOrg owner create IPOrgs
        //

        string[] memory ipAssetTypes = new string[](2);
        ipAssetTypes[0] = "CHARACTER";
        ipAssetTypes[1] = "STORY";
        ipOrg1 = spg.registerIpOrg(
            ipOrgOwner1,
            "IPOrgName1",
            "IPO1",
            ipAssetTypes
        );
        ipOrg2 = spg.registerIpOrg(
            ipOrgOwner2,
            "IPOrgName2",
            "IPO2",
            ipAssetTypes
        );

        vm.label(ipOrg1, "IPOrg_1");
        vm.label(ipOrg2, "IPOrg_2");

        string[] memory ipAssetTypesMore1 = new string[](1);
        string[] memory ipAssetTypesMore2 = new string[](1);
        ipAssetTypesMore1[0] = "MOVIE";
        ipAssetTypesMore2[0] = "MUSIC";

        // TODO: check for event `ModuleConfigured`
        vm.prank(ipOrgOwner1);
        spg.addIPAssetTypes(ipOrg1, ipAssetTypesMore1);

        // TODO: check for event `ModuleConfigured`
        vm.prank(ipOrgOwner2);
        spg.addIPAssetTypes(ipOrg2, ipAssetTypesMore2);

        //
        // IPOrg owner configure modules
        //

        vm.expectEmit(address(registrationModule));
        emit MetadataUpdated(
            address(ipOrg1),
            "http://iporg1.baseuri.url",
            "http://iporg1.contracturi.url"
        );
        vm.prank(ipOrgOwner1);
        spg.setMetadata(
            ipOrg1,
            "http://iporg1.baseuri.url",
            "http://iporg1.contracturi.url"
        );
        assertEq(
            registrationModule.contractURI(address(ipOrg1)),
            "http://iporg1.contracturi.url"
        );
        // TODO: tokenURI check
        // assertEq(registrationModule.tokenURI(address(ipOrg), 1, 0), "");

        vm.expectEmit(address(registrationModule));
        emit MetadataUpdated(
            address(ipOrg2),
            "http://iporg2.baseuri.url",
            "http://iporg2.contracturi.url"
        );
        vm.prank(ipOrgOwner2);
        spg.setMetadata(
            ipOrg2,
            "http://iporg2.baseuri.url",
            "http://iporg2.contracturi.url"
        );
        assertEq(
            registrationModule.contractURI(address(ipOrg2)),
            "http://iporg2.contracturi.url"
        );
        // TODO: tokenURI check
        // assertEq(registrationModule.tokenURI(address(ipOrg), 1, 0), "");

        //
        // IPOrg 1 owner register hooks to RegistrationModule
        //

        address[] memory hooks = new address[](1);
        hooks[0] = tokenGatedHook;

        TokenGated.Config memory tokenGatedConfig = TokenGated.Config({
            tokenAddress: address(mockNFT)
        });
        bytes[] memory hooksConfig = new bytes[](1);
        hooksConfig[0] = abi.encode(tokenGatedConfig);

        vm.expectEmit(address(registrationModule));
        emit HooksRegistered(
            HookRegistry.HookType.PreAction,
            // from _generateRegistryKey(ipOrg_) => registryKey
            keccak256(abi.encode(address(ipOrg1), "REGISTRATION")),
            hooks
        );
        vm.prank(ipOrgOwner1);
        RegistrationModule(registrationModule).registerHooks(
            HookRegistry.HookType.PreAction,
            IIPOrg(ipOrg1),
            hooks,
            hooksConfig
        );

        // protocol admin add relationship type
        LibRelationship.RelatedElements memory allowedElements = LibRelationship
            .RelatedElements({
                src: LibRelationship.Relatables.ADDRESS,
                dst: LibRelationship.Relatables.ADDRESS
            });
        uint8[] memory allowedSrcs = new uint8[](0);
        uint8[] memory allowedDsts = new uint8[](0);
        LibRelationship.AddRelationshipTypeParams
            memory relTypeParams = LibRelationship.AddRelationshipTypeParams({
                relType: "APPEAR_IN",
                ipOrg: ipOrg1,
                allowedElements: allowedElements,
                allowedSrcs: allowedSrcs,
                allowedDsts: allowedDsts
            });
        // TODO: event check for `addRelationshipType` (event `RelationshipTypeSet`)
        vm.prank(ipOrgOwner1);
        spg.addRelationshipType(relTypeParams);

        Licensing.ParamValue[] memory lParams = new Licensing.ParamValue[](3);
        lParams[0] = Licensing.ParamValue({
            tag: "TEST_TAG_1".toShortString(),
            value: abi.encode(true)
        });
        lParams[1] = Licensing.ParamValue({
            tag: "TEST_TAG_2".toShortString(),
            value: abi.encode(222)
        });
        ShortString[] memory ssValue = new ShortString[](2);
        ssValue[0] = "test1".toShortString();
        ssValue[1] = "test2".toShortString();
        lParams[2] = Licensing.ParamValue({
            tag: "TEST_TAG_3".toShortString(),
            value: abi.encode(ssValue)
        });

        Licensing.LicensingConfig memory licensingConfig = Licensing
            .LicensingConfig({
                frameworkId: "test_framework",
                params: lParams,
                licensor: Licensing.LicensorConfig.IpOrgOwnerAlways
            });

        // TODO: event check for `configureIpOrgLicensing` (event `IpOrgTermsSet` emitted twice)
        vm.prank(ipOrgOwner1);
        spg.configureIpOrgLicensing(ipOrg1, licensingConfig);

        // ip asset owner register IP Asset
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
        bytes[] memory preHooksDataCharacter = new bytes[](1);
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
        (uint256 ipAssetId_1, uint256 ipOrg1_AssetId_1) = spg.registerIPAsset(
            ipOrg1,
            registerIpAssetParamsCharacter,
            preHooksDataCharacter,
            new bytes[](0)
        );
        assertEq(ipAssetId_1, 1);
        assertEq(ipOrg1_AssetId_1, 1);

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
        bytes[] memory preHooksDataStory = new bytes[](1);
        preHooksDataStory[0] = abi.encode(tokenGatedHookDataStory);
        vm.prank(ipAssetOwner2);
        (uint256 ipAssetId_2, uint256 ipOrg1_AssetId_2) = spg.registerIPAsset(
            ipOrg1,
            registerIpAssetParamsStory,
            preHooksDataStory,
            new bytes[](0)
        );
        assertEq(ipAssetId_2, 2);
        assertEq(ipOrg1_AssetId_2, 2);

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
        (uint256 ipAssetId_3, uint256 ipOrg2_AssetId_1) = spg.registerIPAsset(
            ipOrg2,
            registerIpAssetParamsOrg2,
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(ipAssetId_3, 3);
        assertEq(ipOrg2_AssetId_1, 1);

        // ip asset owner transfer IP Asset
        // ip asset owner create relationship
        LibRelationship.CreateRelationshipParams
            memory crParams = LibRelationship.CreateRelationshipParams({
                relType: "APPEAR_IN",
                srcAddress: ipOrg1,
                srcId: 1,
                dstAddress: ipOrg1,
                dstId: 2
            });
        bytes[] memory preHooksDataRel = new bytes[](0);
        bytes[] memory postHooksDataRel = new bytes[](0);
        vm.prank(ipOrg1);
        uint256 id = spg.createRelationship(
            ipOrg1,
            crParams,
            preHooksDataRel,
            postHooksDataRel
        );
        assertEq(id, 1);
        LibRelationship.Relationship memory rel = relationshipModule
            .getRelationship(1);
        assertEq(rel.relType, "APPEAR_IN");
        assertEq(rel.srcAddress, ipOrg1);
        assertEq(rel.dstAddress, ipOrg1);
        assertEq(rel.srcId, 1);
        assertEq(rel.dstId, 2);

        // vm.prank(ipOrgOwner1);
        // uint256 lId = spg.createIpaBoundLicense(
        //     ipOrg1,
        //     Licensing.LicenseCreation({
        //         parentLicenseId: 0,
        //         isCommercial: false
        //     }),
        //     1,
        //     new bytes[](0),
        //     new bytes[](0)
        // );
        // Licensing.LicenseData memory license = licenseRegistry.getLicenseData(licenseId);
        // assertFalse(license.isCommercial, "commercial");
        // assertEq(license.ipaId, 1);

        bytes[] memory hooksTransferIPAsset = new bytes[](1);
        hooksTransferIPAsset[0] = abi.encode(ipAssetOwner1);

        vm.expectEmit(address(registrationModule));
        emit IPAssetTransferred(
            1,
            address(ipOrg1),
            1,
            ipAssetOwner1,
            ipAssetOwner2
        );
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

        vm.prank(address(registrationModule));
        vm.expectEmit(address(registry));
        emit IPOrgTransferred(ipAssetId_2, ipOrg1, ipOrg2);
        registry.transferIPOrg(ipAssetId_2, ipOrg2);
        assertEq(registry.ipAssetOrg(ipAssetId_2), ipOrg2);

        vm.prank(address(0)); // TODO: modify when `onlyDisputer` is complete
        emit StatusChanged(ipAssetId_2, 1, 0); // 0 means unset, 1 means set (change when status is converted to ENUM)
        registry.setStatus(ipAssetId_2, 0);
        assertEq(registry.status(ipAssetId_2), 0);
    }

    // function _getTerm(
    //     string memory termId,
    //     Licensing.CommercialStatus comStatus_
    // ) internal pure returns (Licensing.LicensingTerm memory) {
    //     return
    //         Licensing.LicensingTerm({
    //             comStatus: comStatus_,
    //             url: string(abi.encodePacked("https://", termId, ".com")),
    //             hash: "qwertyu",
    //             algorithm: "sha256",
    //             hook: IHook(address(0))
    //         });
    // }
}
