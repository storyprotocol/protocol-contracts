// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";

/// @title LicenseRegistry
/// @notice This contract is the source of truth for all licenses that are registered in the protocol.
/// It will only be called by licensing modules.
/// It should not be upgradeable, so once a license is registered, it will be there forever.
/// Licenses can be made invalid by the revoker, according to the terms of the license.
contract LicenseRegistry is ERC721 {
    // TODO: Figure out data needed for indexing
    event LicenseRegistered(uint256 indexed id);
    event LicenseNftBoundedToIpa(
        uint256 indexed licenseId,
        uint256 indexed ipaId
    );
    event LicenseActivated(uint256 indexed licenseId);
    event LicenseRevoked(uint256 indexed licenseId);

    /// license Id => License
    mapping(uint256 => Licensing.License) private _licenses;
    /// counter for license Ids
    uint256 private _licenseCount;

    IPAssetRegistry public immutable IPA_REGISTRY;
    ModuleRegistry public immutable MODULE_REGISTRY;

    modifier onlyLicensingModule() {
        if (
            !MODULE_REGISTRY.isModule(
                ModuleRegistryKeys.LICENSING_MODULE,
                msg.sender
            )
        ) {
            revert Errors.LicenseRegistry_CallerNotLicensingModule();
        }
        _;
    }

    modifier onlyActiveOrPending(Licensing.LicenseStatus status_) {
        if (
            status_ != Licensing.LicenseStatus.Active &&
            status_ != Licensing.LicenseStatus.Pending
        ) {
            revert Errors.LicenseRegistry_InvalidLicenseStatus();
        }
        _;
    }

    constructor(
        address ipaRegistry_,
        address moduleRegistry_
    ) ERC721("Story Protocol License NFT", "LNFT") {
        if (ipaRegistry_ == address(0)) {
            revert Errors.LicenseRegistry_ZeroIpaRegistryAddress();
        }
        IPA_REGISTRY = IPAssetRegistry(ipaRegistry_);
        if (moduleRegistry_ == address(0)) {
            revert Errors.LicenseRegistry_ZeroModuleRegistryAddress();
        }
        MODULE_REGISTRY = ModuleRegistry(moduleRegistry_);
    }

    /// Creates a License bound to a certain IPA
    /// @param params_ RegistryAddition params
    /// @param ipaId_ id of the bound IPA
    /// @return id of the created license
    function addBoundToIpaLicense(
        Licensing.RegistryAddition memory params_,
        uint256 ipaId_
    )
        external
        onlyLicensingModule
        onlyActiveOrPending(params_.status)
        returns (uint256)
    {
        if (IPA_REGISTRY.status(ipaId_) == 0) {
            revert Errors.LicenseRegistry_InvalidIpa();
        }
        return
            _addLicense(
                Licensing.License({
                    isCommercial: params_.isCommercial,
                    status: params_.status,
                    licenseeType: Licensing.LicenseeType.BoundToIpa,
                    licensor: params_.licensor,
                    revoker: params_.revoker,
                    ipOrg: params_.ipOrg,
                    termIds: params_.termIds,
                    termsData: params_.termsData,
                    ipaId: ipaId_,
                    parentLicenseId: params_.parentLicenseId
                })
            );
    }

    /// Creates a tradeable License NFT.
    /// If the license is to create an IPA in the future, when registering, this license will be
    /// bound to the IPA.
    /// @param params_ RegistryAddition params
    /// @param licensee_ address of the licensee (and owner of the NFT)
    function addTradeableLicense(
        Licensing.RegistryAddition memory params_,
        address licensee_
    ) 
        external
        onlyLicensingModule
        onlyActiveOrPending(params_.status)
        returns (uint256)
    {
        _addLicense(
            Licensing.License({
                isCommercial: params_.isCommercial,
                status: params_.status,
                licenseeType: Licensing.LicenseeType.LNFTHolder,
                licensor: params_.licensor,
                revoker: params_.revoker,
                ipOrg: params_.ipOrg,
                termIds: params_.termIds,
                termsData: params_.termsData,
                ipaId: 0,
                parentLicenseId: params_.parentLicenseId
            })
        );
        _mint(licensee_, _licenseCount);
        return _licenseCount;
    }

    function _addLicense(
        Licensing.License memory license_
    ) private returns (uint256) {
        // Note: Valid parent license must be checked in Licensing module
        _licenses[++_licenseCount] = license_;
        emit LicenseRegistered(_licenseCount);
        return _licenseCount;
    }

    /// Gets License struct for input id
    function getLicense(
        uint256 id_
    ) external view returns (Licensing.License memory) {
        return _licenses[id_];
    }

    /// Gets the address granting a license, by id
    function getLicensor(uint256 id_) external view returns (address) {
        return _licenses[id_].licensor;
    }

    /// Gets the address a license is granted to
    /// @param id_ of the license
    /// @return licensee address, NFT owner if the license is tradeable, or IPA owner if bound to IPA
    function getLicensee(uint256 id_) external view returns (address) {
        Licensing.License storage license = _licenses[id_];
        if (license.licenseeType == Licensing.LicenseeType.Unset) {
            revert Errors.LicenseRegistry_UnknownLicenseId();
        } else if (license.licenseeType == Licensing.LicenseeType.BoundToIpa) {
            return IPA_REGISTRY.ipAssetOwner(license.ipaId);
        } else {
            return ownerOf(id_);
        }
    }

    /// Burns a license NFT and binds the license to an IPA
    /// @param licenseId_ id of the license NFT
    /// @param ipaId_ id of the IPA
    function bindLnftToIpa(
        uint256 licenseId_,
        uint256 ipaId_
    ) external onlyLicensingModule {
        Licensing.License memory license_ = _licenses[licenseId_];
        if (license_.licenseeType != Licensing.LicenseeType.LNFTHolder) {
            revert Errors.LicenseRegistry_NotLicenseNFT();
        }
        _licenses[licenseId_].licenseeType = Licensing.LicenseeType.BoundToIpa;
        _licenses[licenseId_].ipaId = ipaId_;
        _burn(licenseId_);
        emit LicenseNftBoundedToIpa(licenseId_, ipaId_);
    }

    /// Checks if a license is active. If an ancestor is not active, the license is not active
    /// NOTE: this method needs to be optimized, or moved to a merkle tree/scalability solution
    function isLicenseActive(uint256 licenseId_) public view returns (bool) {
        // NOTE: should IPA status check this?
        if (licenseId_ == 0) return false;
        while (licenseId_ != 0) {
            if (_licenses[licenseId_].status != Licensing.LicenseStatus.Active)
                return false;
            licenseId_ = _licenses[licenseId_].parentLicenseId;
        }
        return true;
    }

    /// Called by the licensing module to activate a license, after all the activation terms pass
    /// @param licenseId_ id of the license
    function activateLicense(uint256 licenseId_) external onlyLicensingModule {
        if (_licenses[licenseId_].status != Licensing.LicenseStatus.Pending) {
            revert Errors.LicenseRegistry_LicenseNotPending();
        }
        _licenses[licenseId_].status = Licensing.LicenseStatus.Active;
        // TODO: change IPA status
        emit LicenseActivated(licenseId_);
    }

    /// Revokes a license, making it incactive. Only the revoker can do this.
    /// NOTE: revoking licenses in an already inactive chain should be incentivized, since it
    /// reduces the while loop iterations.
    function revokeLicense(uint256 licenseId_) external {
        if (msg.sender != _licenses[licenseId_].revoker) {
            revert Errors.LicenseRegistry_CallerNotRevoker();
        }
        _licenses[licenseId_].status = Licensing.LicenseStatus.Revoked;
        // TODO: change IPA status
        emit LicenseRevoked(licenseId_);
    }
}
