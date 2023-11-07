// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IPOrg } from "contracts/ip-org/IPOrg.sol";
import { IPAsset } from "contracts/lib/IPAsset.sol";
import { ILicensingModule } from "contracts/interfaces/modules/licensing/ILicensingModule.sol";
import { ITermsProcessor } from "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";


contract RightsManagerHarness is IPOrg {

    function mockMint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function mockMintWithRights(address to, uint256 tokenId, address revoker) external {
        _mint(to, tokenId);
        // _setNonCommercialRights(tokenId, 0, to, revoker, Licensing.IpAssetConfig({
        //     canSublicense: true,
        //     ipAssetOrgRootLicenseId: 0
        // }), Licensing.TermsProcessorConfig({
        //     processor: ITermsProcessor(address(0)),
        //     data: ""
        // }));
    }

    function createLicense_exposed(
        uint256 tokenId,
        uint256 parentLicenseId,
        address licenseHolder,
        string memory uri,
        address revoker,
        bool commercial,
        bool canSublicense,
        Licensing.TermsProcessorConfig memory _terms,
        bool inLicenseRegistry
    ) external returns(uint256 licenseId) {
        // return _createLicense(
        //     tokenId,
        //     parentLicenseId,
        //     licenseHolder,
        //     uri,
        //     revoker,
        //     commercial,
        //     canSublicense,
        //     _terms,
        //     inLicenseRegistry
        // );
    }

}
