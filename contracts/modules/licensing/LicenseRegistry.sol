// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { LicensingFrameworkRepo } from "contracts/modules/licensing/LicensingFrameworkRepo.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ShortString, ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

/// @title LicenseRegistry
/// @notice This contract is the source of truth for all licenses that are registered in the protocol.
/// It will only be called by licensing modules.
/// It should not be upgradeable, so once a license is registered, it will be there forever.
/// Licenses can be made invalid by the revoker, according to the terms of the license.
contract LicenseRegistry is ERC721 {
    using ShortStrings for *;

    // TODO: Figure out data needed for indexing
    event LicenseRegistered(uint256 indexed id);
    event LicenseNftBoundedToIpa(
        uint256 indexed licenseId,
        uint256 indexed ipAssetId
    );
    event LicenseActivated(uint256 indexed licenseId);
    event LicenseRevoked(uint256 indexed licenseId);

    /// license Id => License
    mapping(uint256 => Licensing.LicenseStorage) private _licenses;
    /// counter for license Ids
    uint256 private _licenseCount;

    IPAssetRegistry public immutable IPA_REGISTRY;
    ModuleRegistry public immutable MODULE_REGISTRY;
    LicensingFrameworkRepo public immutable LICENSING_FRAMEWORK_REPO;

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

    modifier onlyLicensingModuleOrLicensee(uint256 licenseId_) {
        if (
            !MODULE_REGISTRY.isModule(
                ModuleRegistryKeys.LICENSING_MODULE,
                msg.sender
            ) ||
            msg.sender != ownerOf(licenseId_)
        ) {
            revert Errors.LicenseRegistry_CallerNotLicensingModuleOrLicensee();
        }
        _;
    }

    modifier onlyActiveOrPending(Licensing.LicenseStatus status_) {
        if (
            status_ != Licensing.LicenseStatus.Active &&
            status_ != Licensing.LicenseStatus.PendingLicensorApproval
        ) {
            revert Errors.LicenseRegistry_InvalidLicenseStatus();
        }
        _;
    }

    modifier onlyActiveParent(uint256 parentLicenseId_) {
        if (parentLicenseId_ != 0) {
            if (!isLicenseActive(parentLicenseId_)) {
                revert Errors.LicenseRegistry_ParentLicenseNotActive();
            }
        }
        _;
    }

    modifier onlyActive(uint256 licenseId_) {
        if (!isLicenseActive(licenseId_)) {
            revert Errors.LicenseRegistry_LicenseNotActive();
        }
        _;
    }

    constructor(
        address ipaRegistry_,
        address moduleRegistry_,
        address licensingFrameworkRepo_
    ) ERC721("Story Protocol License NFT", "LNFT") {
        if (ipaRegistry_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        IPA_REGISTRY = IPAssetRegistry(ipaRegistry_);
        if (moduleRegistry_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        MODULE_REGISTRY = ModuleRegistry(moduleRegistry_);
        if (licensingFrameworkRepo_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        LICENSING_FRAMEWORK_REPO = LicensingFrameworkRepo(
            licensingFrameworkRepo_
        );
    }


    /// Creates a tradeable License NFT.
    /// If the license is to create an IPA in the future, when registering, this license will be
    /// bound to the IPA.
    /// @param regAddition_ RegistryAddition params
    function addLicense(Licensing.RegistryAddition memory regAddition_) 
        external
        onlyLicensingModule
        onlyActiveOrPending(regAddition_.status)
        onlyActiveParent(regAddition_.parentLicenseId)
        returns (uint256) {

        ++_licenseCount;
        _licenses[_licenseCount].status = regAddition_.status;
        _licenses[_licenseCount].licensor = regAddition_.licensor;
        _licenses[_licenseCount].revoker = regAddition_.revoker;
        _licenses[_licenseCount].ipOrg = regAddition_.ipOrg;
        _licenses[_licenseCount].parentLicenseId = regAddition_.parentLicenseId;
        _licenses[_licenseCount].ipaId = regAddition_.ipaId;
        _licenses[_licenseCount].frameworkId = regAddition_.frameworkId;
        // uint256 paramCount = regAddition_.params.length;
        // for (uint256 i = 0; i < paramCount; i++) {
        //     Licensing.ParamValue memory param = regAddition_.params[i];
        //     _licenses[_licenseCount].paramValues[param.tag] = param.value;
        // }

        emit LicenseRegistered(_licenseCount);
        _mint(regAddition_.licensee, _licenseCount);
        if (regAddition_.ipaId != 0) {
            linkLnftToIpa(regAddition_.ipaId, _licenseCount);
        }
        return _licenseCount;
    }


    /// Gets License struct for input id
    function getLicense(
        uint256 id_
    ) public view returns (Licensing.License memory result) {
        Licensing.LicenseStorage storage storedLicense = _licenses[id_];
        result.status = storedLicense.status;
        if (storedLicense.status == Licensing.LicenseStatus.Unset) {
            revert Errors.LicenseRegistry_UnknownLicenseId();
        }
        result.licensor = storedLicense.licensor;
        result.licensee = ownerOf(id_);
        result.revoker = storedLicense.revoker;
        result.ipOrg = storedLicense.ipOrg;
        result.ipaId = storedLicense.ipaId;
        result.parentLicenseId = storedLicense.parentLicenseId;
        result.frameworkId = storedLicense.frameworkId.toString();
        // ParamDefinition[] paramDefs memory = LICENSING_FRAMEWORK_REPO.getParameterDefs(
        //     storedLicense.frameworkId
        // );
        // uint256 paramCount = paramDefs.length;
        
        // bytes[] memory paramValues = new bytes[](paramCount).
        // for (uint256 i = 0; i < paramCount; i++) {
        //     paramValues.push(storedLicense.paramValues[paramDefs[i].tag]);
        // }
        // result.paramDefs = paramDefs;
        // result.paramValues = paramValues;
        return result;
    }

    /// Gets the address granting a license, by id
    function getLicensor(uint256 id_) external view returns (address) {
        return _licenses[id_].licensor;
    }

    /// Gets the address a license is granted to
    /// @param id_ of the license
    /// @return licensee address, NFT owner if the license is tradeable, or IPA owner if bound to IPA
    function getLicensee(uint256 id_) external view returns (address) {
        return ownerOf(id_);
    }

    function getRevoker(uint256 id_) external view returns (address) {
        return _licenses[id_].revoker;
    }

    function getIPOrg(uint256 id_) external view returns (address) {
        return _licenses[id_].ipOrg;
    }

    function getIpaId(uint256 id_) external view returns (uint256) {
        return _licenses[id_].ipaId;
    }

    function getParentLicenseId(uint256 id_) external view returns (uint256) {
        return _licenses[id_].parentLicenseId;
    }

    // function getValueForParamTag(uint256 id_, ShortString tag_)
    //     external
    //     view
    //     returns (bytes memory)
    // {
    //     return _licenses[id_].paramValues[tag_];
    // }

    /// Links the license to an IPA
    /// @param licenseId_ id of the license NFT
    /// @param ipaId_ id of the IPA
    function linkLnftToIpa(
        uint256 licenseId_,
        uint256 ipaId_
    ) public onlyLicensingModuleOrLicensee(licenseId_) {
        _linkNftToIpa(licenseId_, ipaId_);
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
    function activateLicense(uint256 licenseId_, address caller_) external onlyLicensingModule {
        _activateLicense(licenseId_, caller_);
    }

    function activateLicense(uint256 licenseId_) external {
        _activateLicense(licenseId_, msg.sender);
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

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        // TODO
        return "";
    }

    function _linkNftToIpa(uint256 licenseId_, uint256 ipaId_) private onlyActive(licenseId_) {
        if(IPA_REGISTRY.status(ipaId_) != 1) {
            revert Errors.LicenseRegistry_IPANotActive();
        }
        _licenses[licenseId_].ipaId = ipaId_;
        _licenses[licenseId_].status = Licensing.LicenseStatus.Used;
        emit LicenseNftBoundedToIpa(licenseId_, ipaId_);
    }

    function _activateLicense(uint256 licenseId_, address caller_) private {
        Licensing.LicenseStorage storage license = _licenses[licenseId_];
        if (caller_ != license.licensor) {
            revert Errors.LicenseRegistry_CallerNotLicensor();
        }
        if (license.status != Licensing.LicenseStatus.PendingLicensorApproval) {
            revert Errors.LicenseRegistry_LicenseNotPendingApproval();
        }
        if (!isLicenseActive(license.parentLicenseId)) {
            revert Errors.LicenseRegistry_ParentLicenseNotActive();
        }
        license.status = Licensing.LicenseStatus.Active;
        // TODO: change IPA status
        emit LicenseActivated(licenseId_);
    }
}
