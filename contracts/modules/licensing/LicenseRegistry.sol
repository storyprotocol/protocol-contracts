// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { ModuleRegistryKeys } from "contracts/lib/modules/ModuleRegistryKeys.sol";
import { ShortString } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

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

    modifier onlyActiveOrInactive(Licensing.LicenseStatus status_) {
        if (
            status_ != Licensing.LicenseStatus.Active &&
            status_ != Licensing.LicenseStatus.Inactive
        ) {
            revert Errors.LicenseRegistry_InvalidLicenseStatus();
        }
        _;
    }

    constructor(
        address ipaRegistry_,
        address moduleRegistry_
        address 
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
        onlyActiveOrInactive(regAddition_.status)
        returns (uint256)
    {
        if (regAddition_.parentLicenseId != 0) {
            if (!isLicenseActive(regAddition_.parentLicenseId)) {
                revert Errors.LicenseRegistry_ParentLicenseNotActive();
            }
        }

        ++_licenseCount;
        _licenses[_licenseCount].status = regAddition_.status;
        _licenses[_licenseCount].licensor = regAddition_.licensor;
        _licenses[_licenseCount].revoker = regAddition_.revoker;
        _licenses[_licenseCount].ipOrg = regAddition_.ipOrg;
        _licenses[_licenseCount].parentLicenseId = regAddition_.parentLicenseId;
        _licenses[_licenseCount].ipaId = regAddition_.ipaId;
        _licenses[_licenseCount].frameworkId = regAddition_.frameworkId;
        uint256 paramCount = regAddition_.params.length;
        for (uint256 i = 0; i < paramCount; i++) {
            Licensing.ParamValue memory param = regAddition_.params[i];
            _licenses[_licenseCount].paramValues[param.tag] = param.value;
        }

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
    ) external view returns (Licensing.License memory result) {
        Licensing.LicenseStorage storage license_ = _licenses[id_];
        result.status = license_.status;
        result.licensor = license_.licensor;
        result.licensee = ownerOf(id_);
        result.revoker = license_.revoker;
        result.ipOrg = license_.ipOrg;
        result.ipaId = license_.ipaId;
        result.parentLicenseId = license_.parentLicenseId;
        result.frameworkId = license_.frameworkId;
        
        ShortString[] memory frameworkTags = LICENSING_FRAMEWORK_REPO
            .getParameterTags(license_.frameworkId);
        uint256 paramCount = frameworkTags.length;
        result.params = new Licensing.ParamValue[](paramCount);

        for (uint256 i = 0; i < paramCount; i++) {
            ShortString tag = frameworkTags[i];
            result.params[i] = Licensing.ParamValue({
                tag: tag,
                value: license_.paramValues[tag]
            });
        }
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

    function getValueForParamTag(uint256 id_, ShortString memory tag_)
        external
        view
        returns (bytes memory)
    {
        return _licenses[id_].paramValues[tag_];
    }

    /// Links the license to an IPA
    /// @param licenseId_ id of the license NFT
    /// @param ipaId_ id of the IPA
    function linkLnftToIpa(
        uint256 licenseId_,
        uint256 ipaId_
    ) public onlyLicensingModule {
        if(IPA_REGISTRY.status(ipaId_) != 1) {
            revert Errors.LicenseRegistry_IPANotActive();
        }
        Licensing.License memory license_ = _licenses[licenseId_];        
        _licenses[licenseId_].ipaId = ipaId_;
        _licenses[licenseId_].status = Licensing.LicenseStatus.Used;
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
        if (_licenses[licenseId_].status != Licensing.LicenseStatus.Inactive) {
            revert Errors.LicenseRegistry_LicenseNotInactive();
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

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        

        Licensing.License memory license = getLicense(tokenId);

        Registration.IPOrgConfig memory config = ipOrgConfigs[ipOrg_];
        if (bytes(config.baseURI).length != 0) {
            return string(abi.encodePacked(config.baseURI, Strings.toString(id)));
        }

        IPAssetRegistry.IPA memory ipAsset = IPA_REGISTRY.ipAsset(id);

        // Construct the base JSON metadata with custom name format
        string memory baseJson = string(abi.encodePacked(
            '{"name": "Global IP Asset #', Strings.toString(id),
            '", "description": "IP Org Asset Registration Details", "attributes": [',
            '{"trait_type": "Name", "value": "', ipAsset.name, '"},'
        ));

        string memory ipOrgAttributes = string(abi.encodePacked(
            '{"trait_type": "IP Org", "value": "', Strings.toHexString(uint160(ipAsset.ipOrg), 20), '"},',
            '{"trait_type": "Current IP Owner", "value": "', Strings.toHexString(uint160(owner), 20), '"},'
        ));

        string memory ipAssetAttributes = string(abi.encodePacked(
            '{"trait_type": "Initial Registrant", "value": "', Strings.toHexString(uint160(ipAsset.registrant), 20), '"},',
            '{"trait_type": "IP Org Asset Type", "value": "', config.assetTypes[ipOrgAssetType_], '"},',
            '{"trait_type": "Status", "value": "', Strings.toString(ipAsset.status), '"},',
            '{"trait_type": "Hash", "value": "', Strings.toHexString(uint256(ipAsset.hash), 32), '"},',
            '{"trait_type": "Registration Date", "value": "', Strings.toString(ipAsset.registrationDate), '"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string(abi.encodePacked(
                        baseJson,
                        ipOrgAttributes,
                        ipAssetAttributes,
                        ']}'
                    )
                )
            ))
        ));
    }
}
