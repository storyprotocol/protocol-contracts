// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import 'test/foundry/utils/BaseTest.sol';
import 'contracts/modules/relationships/RelationshipModule.sol';
import 'contracts/lib/modules/LibRelationship.sol';
import { AccessControl } from "contracts/lib/AccessControl.sol";
import { Licensing, TermCategories, TermIds } from "contracts/lib/modules/Licensing.sol";
import { OffChain } from "contracts/lib/OffChain.sol";
import { IHook } from "contracts/interfaces/hooks/base/IHook.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";

contract LicensingCreatorModuleConfigTest is BaseTest {
    using ShortStrings for *;

    ShortString public textTermId = "text_term_id".toShortString();
    address ipaOwner = address(0x13333);

    function setUp() override public {
        super.setUp();
        licensingModule.addTermCategory("test_category");
        licensingModule.addTerm(
            "test_category",
            "text_term_id",
            Licensing.LicensingTerm({
                comStatus: Licensing.CommercialStatus.Both,
                text: OffChain.Content({
                    url: "https://example.com"
                }),
                hook: IHook(address(0))
            }
        ));
        Licensing.TermsConfig[] memory nonComTerms = new Licensing.TermsConfig[](1);
        nonComTerms[0] = Licensing.TermsConfig({
            termId: textTermId,
            data: ""
        });
        Licensing.TermsConfig[] memory comTerms = nonComTerms;
        vm.prank(ipOrg.owner());
        spg.configureIpOrgLicensing(
            address(ipOrg),
            Licensing.FrameworkConfig({
                comTermsConfig: comTerms,
                nonComTermsConfig: nonComTerms
            })
        );
        registry.register(IPAsset.RegisterIpAssetParams({
            name: "test",
            ipAssetType: 2,
            owner: ipaOwner,
            ipOrg: (address(ipOrg)),
            hash: keccak256("test"),
            url: "https://example.com",
            data: ""
        }));

    }

    function getTerms(uint256 length) view private returns (Licensing.TermsConfig[] memory ) {
        Licensing.TermsConfig[] memory terms = new Licensing.TermsConfig[](length);
        terms[0] = Licensing.TermsConfig({
            termId: textTermId,
            data: ""
        });
        return terms;
    }

    function test_LicensingModule_configIpOrg_commercialLicenseActivationHooksCanBeSet() public {
        // TODO
    }

    function test_LicensingModule_configIpOrg_nonCommercialLicenseActivationHooksCanBeSet() public {
        // TODO
    }


    function test_LicensingModule_licensing_createsCommercialLicense() public {
    }
    
    function test_LicensingModule_licensing_createsNonCommercialLicense() public {   
    }

    function test_LicensingModule_licensing_createRootLicense() public {
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
        assertTrue(license.isCommercial);

        
        assertTrue(
            relationshipModule.relationshipExists(
                LibRelationship.Relationship({
                    relType: ProtocolRelationships.IPA_LICENSE,
                    srcAddress: address(registry),
                    dstAddress: address(licenseRegistry),
                    srcId: 1,
                    dstId: 1
                })
            )
        );
        //Licensing.License memory license = licenseReg
        // Commercial
        


        
    }

}

