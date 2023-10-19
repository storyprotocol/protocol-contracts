// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Script.sol";
import "script/foundry/utils/StringUtil.sol";
import "script/foundry/utils/JsonDeploymentHandler.s.sol";
import "script/foundry/utils/BroadcastManager.s.sol";
import "contracts/modules/licensing/LicensingModule.sol";

contract SetupFranchiseLicensing is Script, BroadcastManager, JsonDeploymentHandler {

    using StringUtil for uint256;
    using stdJson for string;

    LicensingModule licensingModule;

    // ********* EDIT THESE FOR CONFIG *********
    uint constant FRANCHISE_ID = 250;

    address constant REVOKER_ADDRESS = address(0xB6288e57bf7406B35ab4F70Fd1135E907107e386);
    bool constant ROOT_IP_ASSET_HAS_COMMERCIAL_RIGHTS = false;

    bool constant NON_COMMERCIAL_SUBLICENSING = true;
    uint constant NON_COMMERCIAL_ROOT_LICENSE_ID = 0; // Leave as 0 for now
    ITermsProcessor constant NON_COMMERCIAL_TERMS_PROCESSOR = ITermsProcessor(address(0)); // Leave as 0 for now
    bytes constant NON_COMMERCIAL_TERMS_DATA = abi.encode(''); // Leave as empty for now

    bool constant COMMERCIAL_SUBLICENSING = true;
    uint constant COMMERCIAL_ROOT_LICENSE_ID = 0; // Leave as 0 for now
    ITermsProcessor constant COMMERCIAL_TERMS_PROCESSOR = ITermsProcessor(address(0)); // Leave as empty for now
    bytes constant COMMERCIAL_TERMS_DATA = abi.encode(''); // Leave as empty for now
    string constant COMMERCIAL_LICENSE_URI = "https://commercial.license";


    constructor() JsonDeploymentHandler("") {}

    function run() public {
        _readDeployment();
        _beginBroadcast();
        address licensingAddress = _readAddress(".main.LicensingModule-Proxy");
        if (licensingAddress == address(0)) {
            revert("LicensingModule-Proxy not found");
        }
        
        ILicensingModule.FranchiseConfig memory config = _getLicensingConfig();
        licensingModule = LicensingModule(licensingAddress);
        licensingModule.configureFranchiseLicensing(FRANCHISE_ID, config);
    }

    function _getLicensingConfig() pure internal returns (ILicensingModule.FranchiseConfig memory) {
        return ILicensingModule.FranchiseConfig({
            nonCommercialConfig: ILicensingModule.IpAssetConfig({
                canSublicense: NON_COMMERCIAL_SUBLICENSING,
                franchiseRootLicenseId: NON_COMMERCIAL_ROOT_LICENSE_ID
            }),
            nonCommercialTerms: IERC5218.TermsProcessorConfig({
                processor: NON_COMMERCIAL_TERMS_PROCESSOR,
                data: NON_COMMERCIAL_TERMS_DATA
            }),
            commercialConfig: ILicensingModule.IpAssetConfig({
                canSublicense: COMMERCIAL_SUBLICENSING,
                franchiseRootLicenseId: COMMERCIAL_ROOT_LICENSE_ID
            }),
            commercialTerms: IERC5218.TermsProcessorConfig({
                processor: COMMERCIAL_TERMS_PROCESSOR,
                data: COMMERCIAL_TERMS_DATA
            }),
            rootIpAssetHasCommercialRights: ROOT_IP_ASSET_HAS_COMMERCIAL_RIGHTS,
            revoker: REVOKER_ADDRESS,
            commercialLicenseUri: COMMERCIAL_LICENSE_URI
        });
    }

}
