// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LicenseRegistry is ERC721 {
    event LicenseRegistered(
        uint256 indexed id
    );
    event LicenseNftBoundedToIpa(
        uint256 indexed licenseId,
        uint256 indexed ipaId
    );

    mapping(uint256 => Licensing.License) private _licenses;
    uint256 private _licenseCount;

    IPAssetRegistry public immutable IPA_REGISTRY;

    constructor(
        address ipaRegistry
    ) ERC721("Story Protocol License NFT", "LNFT") {
        if (ipaRegistry == address(0)) {
            revert Errors.LicenseRegistry_ZeroIpaRegistryAddress();
        }
        IPA_REGISTRY = IPAssetRegistry(ipaRegistry);
    }

    function addBoundToIpaLicense(
        Licensing.RegistryAddition memory params_,
        uint256 ipaId_
    ) external returns (uint256) {
        // TODO statuses
        if (IPA_REGISTRY.ipAssetStatus(ipaId_) == 0) {
            revert Errors.LicenseRegistry_InvalidIpa();
        }
        return _addLicense(
            Licensing.License({
                isCommercial: params_.isCommercial,
                licenseeType: Licensing.LicenseeType.BoundToIpa,
                licensor: params_.licensor,
                revoker: params_.revoker,
                ipOrg: params_.ipOrg,
                termIds: params_.termIds,
                termsData: params_.termsData,
                ipaId: ipaId_,
                parentLicenseId: params_.parentLicenseId,
                data: params_.data
            })
        );
    }

    function addTradeableLicense(
        Licensing.RegistryAddition memory params_,
        address licensee_
    ) external returns (uint256) {
        _addLicense(
            Licensing.License({
                isCommercial: params_.isCommercial,
                licenseeType: Licensing.LicenseeType.LNFTHolder,
                licensor: params_.licensor,
                revoker: params_.revoker,
                ipOrg: params_.ipOrg,
                termIds: params_.termIds,
                termsData: params_.termsData,
                ipaId: 0,
                parentLicenseId: params_.parentLicenseId,
                data: params_.data
            })
        );
        _mint(licensee_, _licenseCount);
        return _licenseCount;
    }

    function _addLicense(
        Licensing.License memory license_
    ) private returns (uint256) {
        // TODO: Check valid parent license
        _licenseCount++;
        _licenses[_licenseCount] = license_;
        emit LicenseRegistered(_licenseCount);
        return _licenseCount;
    }

    function getLicense(
        uint256 id_
    ) external view returns (Licensing.License memory) {
        return _licenses[id_];
    }

    function getLicensor(
        uint256 id_
    ) external view returns (address) {
        return _licenses[id_].licensor;
    }

    function getLicensee(
        uint256 id_
    ) external view returns (address) {
        Licensing.LicenseeType licenseeType_ = _licenses[id_].licenseeType;
        if (licenseeType_ == Licensing.LicenseeType.Unset) {
            revert Errors.LicenseRegistry_UnknownLicenseId();
        }
        if (_licenses[id_].licenseeType == Licensing.LicenseeType.BoundToIpa) {
            return IPA_REGISTRY.ipAssetOwner(id_);
        } else  {
            return ownerOf(id_);
        }
    }

    function boundLnftToIpa(
        uint256 id_
    ) external {
        // TODO add Authorization 
        Licensing.License memory license_ = _licenses[id_];
        if (license_.licenseeType != Licensing.LicenseeType.LNFTHolder) {
            revert Errors.LicenseRegistry_NotLicenseNFT();
        }
        _licenses[id_].licenseeType = Licensing.LicenseeType.BoundToIpa;
        _burn(id_);
        emit LicenseNftBoundedToIpa(id_, license_.ipaId);
    }
}
