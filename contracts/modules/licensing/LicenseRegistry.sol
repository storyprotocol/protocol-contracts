// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.19;

import { Licensing } from "contracts/lib/modules/Licensing.sol";
import { IPAssetRegistry } from "contracts/IPAssetRegistry.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { ModuleRegistry } from "contracts/modules/ModuleRegistry.sol";
import { LicensingFrameworkRepo } from "contracts/modules/licensing/LicensingFrameworkRepo.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { ShortStrings } from "@openzeppelin/contracts/utils/ShortStrings.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { LICENSING_MODULE_KEY } from "contracts/lib/modules/Module.sol";

/// @title LicenseRegistry
/// @notice This contract is the source of truth for all licenses that are registered in the protocol.
/// It will only be written by licensing modules.
/// It should not be upgradeable, so once a license is registered, it will be there forever regardless of
/// the ipOrg potentially chaning the licensing framework or Story Protocol doing upgrades.
/// Licenses can be made invalid by the revoker, according to the terms of the license.
contract LicenseRegistry is ERC721 {
    using ShortStrings for *;

    // TODO: Figure out data needed for indexing
    event LicenseRegistered(uint256 indexed id, Licensing.LicenseData licenseData);
    event LicenseNftLinkedToIpa(uint256 indexed licenseId, uint256 indexed ipAssetId);
    event LicenseActivated(uint256 indexed licenseId);
    event LicenseRevoked(uint256 indexed licenseId);

    /// license Id => LicenseData
    mapping(uint256 => Licensing.LicenseData) private _licenses;

    mapping(uint256 => Licensing.ParamValue[]) private _licenseParams;
    /// counter for license Ids
    uint256 private _licenseCount;

    IPAssetRegistry public immutable IPA_REGISTRY;
    ModuleRegistry public immutable MODULE_REGISTRY;
    LicensingFrameworkRepo public immutable LICENSING_FRAMEWORK_REPO;

    modifier onlyLicensingModule() {
        address licensingModule = address(MODULE_REGISTRY.protocolModule(LICENSING_MODULE_KEY));
        if (licensingModule != msg.sender) {
            revert Errors.LicenseRegistry_CallerNotLicensingModule();
        }
        _;
    }

    modifier onlyLicensingModuleOrLicensee(uint256 licenseId_) {
        address licensingModule = address(MODULE_REGISTRY.protocolModule(LICENSING_MODULE_KEY));
        if (licensingModule != msg.sender && msg.sender != ownerOf(licenseId_)) {
            revert Errors.LicenseRegistry_CallerNotLicensingModuleOrLicensee();
        }
        _;
    }

    modifier onlyActiveOrPending(Licensing.LicenseStatus status_) {
        if (status_ != Licensing.LicenseStatus.Active && status_ != Licensing.LicenseStatus.PendingLicensorApproval) {
            revert Errors.LicenseRegistry_InvalidLicenseStatus();
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
        LICENSING_FRAMEWORK_REPO = LicensingFrameworkRepo(licensingFrameworkRepo_);
    }

    /// Creates a tradeable License NFT.
    /// @param newLicense_ LicenseData params
    /// @param licensee_ address of the licensee
    /// @param values_ array of ParamValue structs
    /// @return licenseId_ id of the license NFT
    function addLicense(
        Licensing.LicenseData memory newLicense_,
        address licensee_,
        Licensing.ParamValue[] memory values_
    ) external onlyLicensingModule onlyActiveOrPending(newLicense_.status) returns (uint256) {
        // NOTE: check for parent ipa validity is done in
        // the licensing module
        uint256 licenseId = ++_licenseCount;
        _licenses[licenseId] = newLicense_;
        emit LicenseRegistered(licenseId, newLicense_);
        _mint(licensee_, licenseId);
        uint256 length = values_.length;
        Licensing.ParamValue[] storage params = _licenseParams[licenseId];
        for (uint256 i; i < length; i++) {
            params.push(values_[i]);
        }
        return licenseId;
    }

    /// Create a Derivate License that is reciprocal (all params are inherited
    /// from parent license)
    /// @param parentLicenseId_ id of the parent license
    /// @param licensor_ address of the licensor
    /// @param licensee_ address of the licensee
    /// @param ipaId_ id of the IPA
    /// @return licenseId_ id of the license NFT
    function addReciprocalLicense(
        uint256 parentLicenseId_,
        address licensor_,
        address licensee_,
        uint256 ipaId_
    ) external onlyLicensingModule returns (uint256) {
        if (!isLicenseActive(parentLicenseId_)) {
            revert Errors.LicenseRegistry_ParentLicenseNotActive();
        }
        Licensing.LicenseData memory clone = _licenses[parentLicenseId_];
        uint256 licenseId = ++_licenseCount;
        clone.parentLicenseId = parentLicenseId_;
        clone.licensor = licensor_;
        clone.ipaId = ipaId_;
        if (clone.derivativeNeedsApproval) {
            clone.status = Licensing.LicenseStatus.PendingLicensorApproval;
        }
        _licenseParams[licenseId] = _licenseParams[parentLicenseId_];
        _licenses[licenseId] = clone;
        emit LicenseRegistered(licenseId, clone);
        _mint(licensee_, licenseId);
        return licenseId;
    }

    /// Gets License struct for input id
    function getLicenseData(uint256 id_) public view returns (Licensing.LicenseData memory) {
        Licensing.LicenseData storage license = _licenses[id_];
        if (license.status == Licensing.LicenseStatus.Unset) {
            revert Errors.LicenseRegistry_UnknownLicenseId();
        }
        return license;
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

    function isReciprocal(uint256 id_) external view returns (bool) {
        return _licenses[id_].isReciprocal;
    }

    function isDerivativeAllowed(uint256 id_) external view returns (bool) {
        return _licenses[id_].derivativesAllowed;
    }

    function derivativeNeedsApproval(uint256 id_) external view returns (bool) {
        return _licenses[id_].derivativeNeedsApproval;
    }

    function getParams(uint256 id_) external view returns (Licensing.ParamValue[] memory) {
        return _licenseParams[id_];
    }

    /// Links the license to an IPA
    /// @param licenseId_ id of the license NFT
    /// @param ipaId_ id of the IPA
    function linkLnftToIpa(uint256 licenseId_, uint256 ipaId_) public onlyLicensingModuleOrLicensee(licenseId_) {
        _linkNftToIpa(licenseId_, ipaId_);
    }

    /// Checks if a license is active. If an ancestor is not active, the license is not active
    /// NOTE: this method is for alpha/illustration purposes.
    // It's implementation will require a scalability solution
    function isLicenseActive(uint256 licenseId_) public view returns (bool) {
        if (licenseId_ == 0) return false;
        while (licenseId_ != 0) {
            if (
                _licenses[licenseId_].status == Licensing.LicenseStatus.PendingLicensorApproval ||
                _licenses[licenseId_].status == Licensing.LicenseStatus.Unset ||
                _licenses[licenseId_].status == Licensing.LicenseStatus.Revoked
            ) return false;
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

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        Licensing.LicenseData memory license = getLicenseData(tokenId);
        // Construct the base JSON metadata with custom name format
        string memory baseJson = string(
            /* solhint-disable */
            abi.encodePacked(
                '{"name": "Story Protocol License NFT #',
                Strings.toString(tokenId),
                '", "description": "License agreement stating the terms of a Story Protocol IP Org", "attributes": ['
            )
            /* solhint-enable */
        );

        string memory licenseAttributes1 = string(
            /* solhint-disable */
            abi.encodePacked(
                '{"trait_type": "IP Org", "value": "',
                Strings.toHexString(uint160(license.ipOrg), 20),
                '"},',
                '{"trait_type": "Framework ID", "value": "',
                license.frameworkId.toString(),
                '"},',
                '{"trait_type": "Framework URL", "value": "',
                LICENSING_FRAMEWORK_REPO.getLicenseTextUrl(license.frameworkId.toString()),
                '"},',
                '{"trait_type": "Status", "value": "',
                Licensing.statusToString(license.status),
                '"},'
            )
            /* solhint-enable */
        );

        string memory licenseAttributes2 = string(
            /* solhint-disable */
            abi.encodePacked(
                '{"trait_type": "Licensor", "value": "',
                Strings.toHexString(uint160(license.licensor), 20),
                '"},',
                '{"trait_type": "Licensee", "value": "',
                Strings.toHexString(uint160(_ownerOf(tokenId)), 20),
                '"},',
                '{"trait_type": "Revoker", "value": "',
                Strings.toHexString(uint160(license.revoker), 20),
                '"},',
                '{"trait_type": "Parent License ID", "value": "',
                Strings.toString(license.parentLicenseId),
                '"},',
                '{"trait_type": "Derivative IPA", "value": "',
                Strings.toString(license.ipaId),
                '"},'
            )
            /* solhint-enable */
        );
        Licensing.ParamValue[] memory params = _licenseParams[tokenId];
        uint256 paramCount = params.length;
        string memory paramAttributes;
        for (uint256 i = 0; i < paramCount; i++) {
            Licensing.ParamDefinition memory paramDef = LICENSING_FRAMEWORK_REPO.getParamDefinition(
                license.frameworkId.toString(),
                params[i].tag
            );
            string memory value = Licensing.getDecodedParamString(paramDef, params[i].value);

            if (
                paramDef.paramType != Licensing.ParameterType.MultipleChoice &&
                paramDef.paramType != Licensing.ParameterType.ShortStringArray
            ) {
                value = string(abi.encodePacked('"', value, '"}')); // solhint-disable-line
            } else {
                value = string(abi.encodePacked(value, "}"));
            }
            paramAttributes = string(
                abi.encodePacked(
                    paramAttributes,
                    '{"trait_type": "', // solhint-disable-line
                    params[i].tag.toString(),
                    '", "value": ', // solhint-disable-line
                    value
                )
            );
            if (i != paramCount - 1) {
                paramAttributes = string(abi.encodePacked(paramAttributes, ","));
            } else {
                paramAttributes = string(abi.encodePacked(paramAttributes, "]"));
            }
        }

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(baseJson, licenseAttributes1, licenseAttributes2, paramAttributes, "}")
                            )
                        )
                    )
                )
            );
    }

    function _linkNftToIpa(uint256 licenseId_, uint256 ipaId_) private onlyActive(licenseId_) {
        if (IPA_REGISTRY.status(ipaId_) != 1) {
            revert Errors.LicenseRegistry_IPANotActive();
        }
        if (_licenses[licenseId_].ipaId != 0) {
            revert Errors.LicenseRegistry_LicenseAlreadyLinkedToIpa();
        }
        _licenses[licenseId_].ipaId = ipaId_;
        emit LicenseNftLinkedToIpa(licenseId_, ipaId_);
    }

    function _activateLicense(uint256 licenseId_, address caller_) private {
        Licensing.LicenseData storage license = _licenses[licenseId_];
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
