// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IPAssetRegistry } from "contracts/ip-assets/IPAssetRegistry.sol";
import { IPAsset } from "contracts/IPAsset.sol";
import { ILicensingModule } from "contracts/modules/licensing/ILicensingModule.sol";
import { IERC5218 } from "contracts/modules/licensing/IERC5218.sol";
import { ITermsProcessor } from "contracts/modules/licensing/terms/ITermsProcessor.sol";


contract RightsManagerHarness is IPAssetRegistry {

    constructor(address _eventEmitter, address _licensingModule, address _franchiseRegistry, address _collectModule)
        IPAssetRegistry(_eventEmitter, _licensingModule, _franchiseRegistry, _collectModule) {
        
    }

    function mockMint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function mockMintWithRights(address to, uint256 tokenId, address revoker) external {
        _mint(to, tokenId);
        _setNonCommercialRights(tokenId, 0, to, revoker, ILicensingModule.IpAssetConfig({
            canSublicense: true,
            franchiseRootLicenseId: 0
        }), IERC5218.TermsProcessorConfig({
            processor: ITermsProcessor(address(0)),
            data: ""
        }));
    }

    function createLicense_exposed(
        uint256 tokenId,
        uint256 parentLicenseId,
        address licenseHolder,
        string memory uri,
        address revoker,
        bool commercial,
        bool canSublicense,
        TermsProcessorConfig memory _terms,
        bool inLicenseRegistry
    ) external returns(uint256 licenseId) {
        return _createLicense(
            tokenId,
            parentLicenseId,
            licenseHolder,
            uri,
            revoker,
            commercial,
            canSublicense,
            _terms,
            inLicenseRegistry
        );
    }

}
