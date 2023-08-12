// SPDX-License-Identifier: BUSDL-1.1
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import './utils/BaseTest.sol';
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
                bytes4(keccak256(bytes("initialize(string,address)"))), noncommercialLicenseURL, address(accessControl)
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
        LicensingModule.DemoTerms memory terms = LicensingModule.DemoTerms({
            imageURI: "https://imgs.search.brave.com/BTQd7FLJIG2gx5fNTzevIycsnm8JMWKSrBeQawWG3hI/rs:fit:860:0:0/g:ce/aHR0cHM6Ly93d3cu/bWVtZS1hcnNlbmFs/LmNvbS9tZW1lcy9k/ZTk2ODRiOWU0NDI3/MWI4MmUxMjQ4Mzgy/ODA1YWUxMC5qcGc",
            usage: "yes",
            duration: "forever",
            rights: "all",
            name: "name"
        });
        uint256 licenseId = franchiseRegistry.createLicense(1, ipAssetId, true, keccak256("MOVIE_ADAPTATION"), "https://cool-license-bro.pdf", terms);
        console.log(licensingModule.tokenURI(licenseId));
        vm.stopPrank();
    }
 
}
