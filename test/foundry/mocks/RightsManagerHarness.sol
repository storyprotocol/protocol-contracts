// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import { IPAssetRegistry } from "contracts/ip-assets/IPAssetRegistry.sol";

contract RightsManagerHarness is IPAssetRegistry {

    constructor(address _eventEmitter, address _licensingModule, address _franchiseRegistry)
        IPAssetRegistry(_eventEmitter, _licensingModule, _franchiseRegistry) {

    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
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