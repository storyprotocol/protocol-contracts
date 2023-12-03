/* solhint-disable contract-name-camelcase, func-name-mixedcase */
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
import { TermsRepository } from "contracts/modules/licensing/TermsRepository.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { TermCategories, TermIds } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
import { BaseTest } from "test/foundry/utils/BaseTest.sol";
import { LibRelationship } from "contracts/lib/modules/LibRelationship.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { TermsData } from "contracts/lib/modules/ProtocolLicensingTerms.sol";
import { Registration } from "contracts/lib/modules/Registration.sol";
import { IE2ETest } from "test/foundry/interfaces/IE2ETest.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

contract E2ETest is IE2ETest, BaseTest {
    using ShortStrings for string;

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
        _grantRole(vm, AccessControl.TERMS_SETTER_ROLE, admin);
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

        // configure license terms
        vm.startPrank(admin);
        Licensing.CommercialStatus comStatus = Licensing.CommercialStatus.Both;

        vm.expectEmit(address(termsRepository));
        emit TermCategoryAdded(TermCategories.SHARE_ALIKE);
        termsRepository.addCategory(TermCategories.SHARE_ALIKE);
        Licensing.LicensingTerm memory term = _getTerm(
            TermIds.NFT_SHARE_ALIKE,
            comStatus
        );

        vm.expectEmit(address(termsRepository));
        emit TermAdded(TermCategories.SHARE_ALIKE, TermIds.NFT_SHARE_ALIKE);
        termsRepository.addTerm(
            TermCategories.SHARE_ALIKE,
            TermIds.NFT_SHARE_ALIKE,
            term
        );

        vm.expectEmit(address(termsRepository));
        emit TermCategoryAdded(TermCategories.LICENSOR);
        termsRepository.addCategory(TermCategories.LICENSOR);
        term = _getTerm(TermIds.LICENSOR_APPROVAL, comStatus);

        vm.expectEmit(address(termsRepository));
        emit TermAdded(TermCategories.LICENSOR, TermIds.LICENSOR_APPROVAL);
        termsRepository.addTerm(
            TermCategories.LICENSOR,
            TermIds.LICENSOR_APPROVAL,
            term
        );

        vm.expectEmit(true, true, true, true);
        emit TermCategoryAdded(TermCategories.CATEGORIZATION);
        termsRepository.addCategory(TermCategories.CATEGORIZATION);
        term = _getTerm(TermIds.FORMAT_CATEGORY, comStatus);
        vm.expectEmit(true, true, true, true);
        emit TermAdded(TermCategories.CATEGORIZATION, TermIds.FORMAT_CATEGORY);
        termsRepository.addTerm(
            TermCategories.CATEGORIZATION,
            TermIds.FORMAT_CATEGORY,
            term
        );

        vm.expectEmit(true, true, true, true);
        emit TermCategoryAdded(TermCategories.ACTIVATION);
        termsRepository.addCategory(TermCategories.ACTIVATION);
        term = _getTerm(TermIds.LICENSOR_IPORG_OR_PARENT, comStatus);
        vm.expectEmit(true, true, true, true);
        emit TermAdded(
            TermCategories.ACTIVATION,
            TermIds.LICENSOR_IPORG_OR_PARENT
        );
        termsRepository.addTerm(
            TermCategories.ACTIVATION,
            TermIds.LICENSOR_IPORG_OR_PARENT,
            term
        );

        // assertTrue(
        //     Strings.equal(
        //         termsRepository.getTerm(TermIds.LICENSOR_IPORG_OR_PARENT).url,
        //         ""
        //     )
        // );

        // vm.expectEmit(address(termsRepository));
        // emit TermCategoryRemoved(TermCategories.ACTIVATION);
        // termsRepository.removeCategory(TermCategories.ACTIVATION);

        vm.stopPrank();
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

        // ip org owner configure IpOrg Licensing
        // no commercial terms
        Licensing.TermsConfig memory comTermsConfig = Licensing.TermsConfig({
            termIds: new ShortString[](0),
            termData: new bytes[](0)
        });

        // non commercial terms
        // all licensors would be ipOrg
        // all licenses begin as Pending, isLicenseActive == false,
        // need approval from licensor to activate them
        ShortString[] memory termIds_ = new ShortString[](3);
        bytes[] memory termsData_ = new bytes[](3);
        termIds_[0] = TermIds.NFT_SHARE_ALIKE.toShortString();
        termsData_[0] = abi.encode(true);
        termIds_[1] = TermIds.LICENSOR_APPROVAL.toShortString();
        termsData_[1] = abi.encode(true);
        termIds_[2] = TermIds.LICENSOR_IPORG_OR_PARENT.toShortString();
        termsData_[2] = abi.encode(TermsData.LicensorConfig.IpOrg);

        Licensing.TermsConfig memory nonComTermsConfig = Licensing.TermsConfig({
            termIds: termIds_,
            termData: termsData_
        });

        Licensing.FrameworkConfig memory frameworkConfig = Licensing
            .FrameworkConfig({
                comTermsConfig: comTermsConfig,
                nonComTermsConfig: nonComTermsConfig
            });

        // TODO: event check for `configureIpOrgLicensing` (event `IpOrgTermsSet` emitted twice)
        vm.prank(ipOrgOwner1);
        spg.configureIpOrgLicensing(ipOrg1, frameworkConfig);

        // ip asset owner register IP Asset
        uint ipAssetId;
        uint ipOrgAssetId;
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
        (ipAssetId, ipOrgAssetId) = spg.registerIPAsset(
            ipOrg1,
            registerIpAssetParamsCharacter,
            preHooksDataCharacter,
            new bytes[](0)
        );
        assertEq(ipAssetId, 1);
        assertEq(ipOrgAssetId, 1);

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
        (ipAssetId, ipOrgAssetId) = spg.registerIPAsset(
            ipOrg1,
            registerIpAssetParamsStory,
            preHooksDataStory,
            new bytes[](0)
        );
        assertEq(ipAssetId, 2);
        assertEq(ipOrgAssetId, 2);

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
        (ipAssetId, ipOrgAssetId) = spg.registerIPAsset(
            ipOrg2,
            registerIpAssetParamsOrg2,
            new bytes[](0),
            new bytes[](0)
        );
        assertEq(ipAssetId, 3);
        assertEq(ipOrgAssetId, 1);

        // ip asset owner transfer IP Asset
        // ip asset owner create relationship
        LibRelationship.CreateRelationshipParams memory params = LibRelationship
            .CreateRelationshipParams({
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
            params,
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

        vm.prank(ipOrgOwner1);
        uint256 lId = spg.createIpaBoundLicense(
            ipOrg1,
            Licensing.LicenseCreation({
                parentLicenseId: 0,
                isCommercial: false
            }),
            1,
            new bytes[](0),
            new bytes[](0)
        );
        Licensing.License memory license = licenseRegistry.getLicense(lId);
        assertFalse(license.isCommercial, "commercial");
        assertEq(license.ipaId, 1);

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
    }

    function _getTerm(
        string memory termId,
        Licensing.CommercialStatus comStatus_
    ) internal pure returns (Licensing.LicensingTerm memory) {
        return
            Licensing.LicensingTerm({
                comStatus: comStatus_,
                url: string(abi.encodePacked("https://", termId, ".com")),
                hash: "qwertyu",
                algorithm: "sha256",
                hook: IHook(address(0))
            });
    }

    // function _getExecutionContext(
    //     bytes memory hookConfig_,
    //     bytes memory hookParams_
    // ) internal pure returns (bytes memory) {
    //     Hook.ExecutionContext memory context = Hook.ExecutionContext({
    //         config: hookConfig_,
    //         params: hookParams_
    //     });
    //     return abi.encode(context);
    // }
}
