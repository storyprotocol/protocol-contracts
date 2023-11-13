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
import { BaseLicensingTest } from "./BaseLicensingTest.sol";

contract LicensingCreatorModuleConfigTest is BaseLicensingTest {
    using ShortStrings for *;

    address ipaOwner = address(0x13333);

    function setUp() override public {
        super.setUp();
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

    function test_LicensingModule_licensing_createsCommerciaSublLicense() public {

    }

    function test_LicensingModule_licensing_createsNonCommercialSubLicense() public {
        
    }

}

