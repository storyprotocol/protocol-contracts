// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/BaseTest.sol';
/*
import { LicensingModule } from "contracts/modules/licensing/LicensingModule.sol";

contract LicenseModuleTest is BaseTest {

    LicensingModule licensingModule;
    string noncommercialLicenseURL;
    address ipAssetHolder = address(0x23232);

    function setUp() virtual override public {
        deployProcessors = false;
        super.setUp();
        address licenseModuleImpl = address(new LicensingModule(address(franchiseRegistry)));        

        noncommercialLicenseURL = "https://arweave.net/yHIbKlFBg3xuKSzlM_dREG8Y08uod-gWKsWi9OaPFsM";

        address proxy = _deployUUPSProxy(
            licenseModuleImpl,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("initialize(string)"))), noncommercialLicenseURL
            )
        );
        licensingModule = LicensingModule(proxy);
        franchiseRegistry.setLicensingModule(licensingModule);
    }

    function test_setUp() public {
        assertEq(address(franchiseRegistry.getLicenseingModule()), address(licensingModule));
        assertEq(licensingModule.getNonCommercialLicenseURI(), noncommercialLicenseURL);
    }

    function test_happyPath() public {
        vm.startPrank(ipAssetHolder);
        uint256 ipAssetId = franchiseRegistry.createIPAsset(1, IPAsset.STORY, "name", "description", "tokenURI");
        franchiseRegistry.createLicense(1, ipAssetId, true, keccak256("MOVIE_ADAPTATION"), "https://cool-license-bro.pdf");
        vm.stopPrank();
    }
 
}
*/