// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { LibDuration } from "../timing/LibDuration.sol";
import { IERC5218 } from "contracts/interfaces/modules/licensing/IERC5218.sol";
import { ILicenseRegistry } from "contracts/interfaces/modules/licensing/ILicenseRegistry.sol";
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { ERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import { ITermsProcessor } from "contracts/interfaces/modules/licensing/terms/ITermsProcessor.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { Licensing } from "contracts/lib/modules/Licensing.sol";

/// @title RightsManager
/// @author Raul Martinez
/// @notice  IERC-5218 implementation.
/// Allows us to grant 2 type of licenses:
/// 1. Rights: Licenses tied to a tokenId (IPAsset id), in which the license holder is always the owner of the tokenId. Each tokenId can have commercial or non commercial license tied to it defining it.
/// 2. Tradeable Licenses): The license holder is the owner of the correspondent LicenseRegistry NFT. They are either:
/// 2.1 Franchise root license: LicenseRegistry enabled license minted by a Franchise owner to govern commercial or non commercial rights for all the IPAssetRegistries.
/// 2.2 Sublicense: a license coming from Rights or other Licenses, minted by the parent license owner. These would be the future "movie adaptation" type licenses that can be sold.
/// Allows license holders to execute terms to activate the license to activate them.
/// Tracks active licenses along the license trees.
abstract contract RightsManager is
    ERC721Upgradeable,
    IERC5218
{
    using ERC165CheckerUpgradeable for address;

    struct RightsManagerStorage {
        mapping(uint256 => Licensing.License) licenses;
        // keccack256(commercial, tokenId) => licenseId
        mapping(bytes32 => uint256) licensesForTokenId;
        uint256 licenseCounter;
        ILicenseRegistry licenseRegistry;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.rights-manager.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x315576c20e31e03ef3e70482445a4c33e45baf13beff28e79f2adf6d06cc0bee;
    uint256 private constant _UNSET_LICENSE_ID = 0;
    uint256 public constant FRANCHISE_REGISTRY_OWNED_TOKEN_ID = type(uint256).max;
    IERC721 public immutable FRANCHISE_REGISTRY;

    constructor(address franchiseRegistry_) {
        if (franchiseRegistry_ == address(0)) {
            revert Errors.ZeroAddress();
        }
        FRANCHISE_REGISTRY = IERC721(franchiseRegistry_);

    }

    function __RightsManager_init(
        string calldata name_,
        string calldata symbol_
    ) public initializer {
        __ERC721_init(name_, symbol_);
    }


    function setLicenseRegistry(address licenseRegistry_) external {
        // NOTE: This assumes no need to change ILicenseRegistry implementation.
        if (address(_getRightsManagerStorage().licenseRegistry) != address(0)) revert Errors.Unauthorized();
        if  (licenseRegistry_ == address(0)) revert Errors.ZeroAddress();
        _getRightsManagerStorage().licenseRegistry = ILicenseRegistry(licenseRegistry_);
    }

    function _getRightsManagerStorage()
        private
        pure
        returns (RightsManagerStorage storage $)
    {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }

    
    /// Creates a tradeable sublicense.
    /// @dev Throws if trying to create a franchise level or root license.
    /// @param tokenId_ The tokenId of the IPAsset to create the sublicense for.
    /// @param parentLicenseId_  The parent license to create the sublicense from.
    /// @param licenseHolder_ The address of the sublicense holder, will own the ILicenseRegistry NFT.
    /// @param uri_ License terms URI.
    /// @param revoker_ address that can revoke the license.
    /// @param commercial_ if the license is commercial or not.
    /// @param canSublicense_ if the license can be parentLicense of another one
    /// @param terms_ the on chain terms of the license, via executor and data
    /// @return licenseId
    function createLicense(
        uint256 tokenId_, // Question: should sublicenses be created with a tokenId or just a parentLicenseId?
        uint256 parentLicenseId_,
        address licenseHolder_,
        string memory uri_,
        address revoker_,
        bool commercial_,
        bool canSublicense_,
        Licensing.TermsProcessorConfig memory terms_
    ) external override returns (uint256) {
        if (tokenId_ == FRANCHISE_REGISTRY_OWNED_TOKEN_ID || parentLicenseId_ == _UNSET_LICENSE_ID) {
            revert Errors.RightsManager_UseCreateFranchiseRootLicenseInstead();
        }
        if (msg.sender != getLicenseHolder(parentLicenseId_)) revert Errors.Unauthorized();
        return _createLicense(
            tokenId_,
            parentLicenseId_,
            licenseHolder_,
            uri_,
            revoker_,
            commercial_,
            canSublicense_,
            terms_,
            true
        );
    }

    
    /// Creates the root licenses that all other licenses of a Franchise may be based on.
    /// @dev Throws if caller not owner of the FranchiseRegistry NFt.
    /// @param franchiseId_ in the FranhiseRegistry
    /// @param licenseHolder_ The address of the sublicense holder, will own the ILicenseRegistry NFT.
    /// @param uri_ License terms URI.
    /// @param revoker_ address that can revoke the license.
    /// @param commercial_ if the license is commercial or not.
    /// @param canSublicense_ if the license can be parentLicense of another one
    /// @param terms_ the on chain terms of the license, via executor and data
    /// @return licenseId
    function createFranchiseRootLicense(
        uint256 franchiseId_,
        address licenseHolder_,
        string memory uri_,
        address revoker_,
        bool commercial_,
        bool canSublicense_,
        Licensing.TermsProcessorConfig memory terms_
    ) external returns (uint256) {
        if (msg.sender != FRANCHISE_REGISTRY.ownerOf(franchiseId_)) revert Errors.Unauthorized();
        return _createLicense(
            FRANCHISE_REGISTRY_OWNED_TOKEN_ID,
            _UNSET_LICENSE_ID,
            licenseHolder_,
            uri_,
            revoker_,
            commercial_,
            canSublicense_,
            terms_,
            true
        );
    }


    function _createLicense(
        uint256 tokenId_,
        uint256 parentLicenseId_,
        address licenseHolder_,
        string memory uri_,
        address revoker_,
        bool commercial_,
        bool canSublicense_,
        Licensing.TermsProcessorConfig memory terms_,
        bool inLicenseRegistry_
    ) internal returns (uint256) {
        // TODO: should revoker come from allowed revoker list?
        if (revoker_ == address(0)) revert Errors.RightsManager_ZeroRevokerAddress();
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        // Only licenses minted to the FranchiseRegistry Owner as a root license should
        // have tokenId = FRANCHISE_REGISTRY_OWNED_TOKEN_ID, otherwise the tokenId should be a minted NFT (IPAsset.IPAssetType)
        // Checks for the FranchiseRegistry Owner should be done in the calling function
        if (tokenId_ != FRANCHISE_REGISTRY_OWNED_TOKEN_ID) {
            if (!_exists(tokenId_)) {
                revert Errors.NonExistentID(tokenId_);
            }
        }
        // If this is not a LicenseRegsitry license, check that the tokenId doesn't already have a root license
        if (!inLicenseRegistry_) {
            if ($.licensesForTokenId[keccak256(abi.encode(commercial_, tokenId_))] != _UNSET_LICENSE_ID) {
                revert Errors.RightsManager_AlreadyHasRootLicense();
            }
        } else {
            if($.licenseRegistry == ILicenseRegistry(address(0))) revert Errors.RightsManager_LicenseRegistryNotConfigured();
            if(tokenId_ != FRANCHISE_REGISTRY_OWNED_TOKEN_ID && parentLicenseId_ != _UNSET_LICENSE_ID) {
                // If this is a sublicense, check that this is a valid sublicense
                Licensing.License memory parentLicense = $.licenses[parentLicenseId_];
                if (!parentLicense.active) revert Errors.RightsManager_InactiveParentLicense();
                if (!parentLicense.canSublicense) revert Errors.RightsManager_CannotSublicense();
                if (parentLicense.commercial != commercial_) revert Errors.RightsManager_CommercialTermsMismatch();
                if (getLicenseHolder(parentLicenseId_) != licenseHolder_) revert Errors.RightsManager_NotOwnerOfParentLicense();
            }
        }
        // Check that the terms are valid
        _verifyTerms(terms_);

        // Create the license and increment the licenseCounter
        uint256 licenseId = ++$.licenseCounter;
        $.licenses[licenseId] = Licensing.License({
            active: true,
            canSublicense: canSublicense_,
            commercial: commercial_,
            parentLicenseId: parentLicenseId_,
            tokenId: tokenId_,
            revoker: revoker_,
            uri: uri_,
            termsProcessor: terms_.processor,
            termsData: terms_.data
        });
        
        // Mint the license in the LicenseRegistry if requested. Should not do this for IPAsset Rights, but
        // the checks on inLicenseRegistry should be done in the calling function
        if (inLicenseRegistry_) {
            $.licenseRegistry.mint(licenseHolder_, licenseId);
        } else {
            // Save tokenId => licenseId relationship IF this is a root license
            $.licensesForTokenId[keccak256(abi.encode(commercial_, tokenId_))] = licenseId;
        }

        // Emit events
        emit CreateLicense(
            licenseId,
            tokenId_,
            parentLicenseId_,
            licenseHolder_,
            uri_,
            revoker_
        );
        emit TransferLicense(licenseId, licenseHolder_);
        return licenseId;
    }


    function revokeLicense(uint256 licenseId_) external override {
        if (!isLicenseSet(licenseId_)) revert Errors.NonExistentID(licenseId_);
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        Licensing.License storage license = $.licenses[licenseId_];
        if (msg.sender != license.revoker) revert Errors.RightsManager_SenderNotRevoker();
        license.active = false;
        emit RevokeLicense(licenseId_);
        // TODO: should we burn the license if it's from the LicenseRegistry?
        // TODO: delete the rootLicenseForTokenId mapping for licenseId if root license
    }

    
    /// If set, runs the TermsExecutor with the terms data stored in the license.
    /// If the terms execution returns different data, the license is updated with the new data.
    /// @param licenseId_ The identifier for the queried license
    function executeTerms(uint256 licenseId_) external {
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        if (msg.sender != $.licenseRegistry.ownerOf(licenseId_)) revert Errors.Unauthorized();
        Licensing.License storage license = $.licenses[licenseId_];
        if (license.termsProcessor != ITermsProcessor(address(0))) {
            bytes memory newData = license.termsProcessor.executeTerms(license.termsData);
            if (keccak256(license.termsData) != keccak256(newData)) {
                license.termsData = newData;
                emit TermsUpdated(licenseId_, address(license.termsProcessor), newData);
            }
        }
        emit ExecuteTerms(licenseId_, license.termsData);
    }

    /// returns true if the license is active (non revoked and terms returning true) and all its parent licenses are active, false otherwise
    function isLicenseActive(
        uint256 licenseId_
    ) public view virtual returns (bool) {
        // TODO: limit to the tree depth
        if (licenseId_ == 0) return false;
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        while (licenseId_ != 0) {
            Licensing.License memory license = $.licenses[licenseId_];
            if (!_isActiveAndTermsOk(license)) return false;
            licenseId_ = license.parentLicenseId;
        }
        return true;
    }

    function _isActiveAndTermsOk(Licensing.License memory license_) view private returns (bool) {
        if (address(license_.termsProcessor) == address(0)) return license_.active;
        return license_.active && license_.termsProcessor.termsExecutedSuccessfully(license_.termsData);
    }

    function getLicense(uint256 licenseId_) public view returns (Licensing.License memory, address holder) {
        return (
            _getRightsManagerStorage().licenses[licenseId_],
            getLicenseHolder(licenseId_)
        );
    }

    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 firstTokenId_,
        uint256 batchSize_
    ) internal virtual override {
        if (from_ != address(0)) {
            for (uint256 i = firstTokenId_; i < batchSize_;) {
                _verifyRightsTransfer(from_, to_, i);
                unchecked {
                    i++;
                }
            }
        }
        super._beforeTokenTransfer(from_, to_, firstTokenId_, batchSize_);
    }
    
    function _verifyRightsTransfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal {
        // TODO: trigger rights transfer check, check granting terms, banned marketplaces, etc.
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        // NOTE: We are assuming a revoked Non Commercial License impedes the transfer of the NFT.
        // Should revoked commercial rights also impede the transfer?
        uint256 licenseId = $.licensesForTokenId[keccak256(abi.encode(false, tokenId_))];
        if (licenseId != _UNSET_LICENSE_ID) revert Errors.RightsManager_NFTHasNoAssociatedLicense(); // This should not happen, if fired there is a bug somewhere
        if (isLicenseActive(licenseId)) revert Errors.RightsManager_InactiveLicense(); // NOTE: Should we freeze invalid licenses? burn them?
        emit TransferLicense(licenseId, to_);
    }

    function _verifyTerms(Licensing.TermsProcessorConfig memory terms_) private view {
        if  (address(terms_.processor) != address(0) &&
            !terms_.processor.supportsInterface(type(ITermsProcessor).interfaceId)) {
            revert Errors.UnsupportedInterface("ITermsProcessor");
        }
    }

    function getLicenseTokenId(
        uint256 licenseId_
    ) external view override returns (uint256) {
        return _getRightsManagerStorage().licenses[licenseId_].tokenId;
    }

    function getParentLicenseId(
        uint256 licenseId_
    ) external view override returns (uint256) {
        return _getRightsManagerStorage().licenses[licenseId_].parentLicenseId;
    }


    function getLicenseHolder(
        uint256 licenseId_
    ) public view override returns (address) {
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        if ($.licenseRegistry.exists(licenseId_)) {
            return $.licenseRegistry.ownerOf(licenseId_);
        } else {
            Licensing.License storage license = $.licenses[
                licenseId_
            ];
            return ownerOf(license.tokenId);
        }
    }

    function getLicenseURI(
        uint256 licenseId_
    ) external view override returns (string memory) {
        return _getRightsManagerStorage().licenses[licenseId_].uri;
    }

    function getLicenseRevoker(
        uint256 licenseId_
    ) external view override returns (address) {
        return _getRightsManagerStorage().licenses[licenseId_].revoker;
    }

    function getLicenseIdByTokenId(
        uint256 tokenId_,
        bool commercial_
    ) public view override returns (uint256) {
        return
            _getRightsManagerStorage().licensesForTokenId[
                keccak256(abi.encode(commercial_, tokenId_))
            ];
    }

    function getLicenseRegistry() external view returns (ILicenseRegistry) {
        return _getRightsManagerStorage().licenseRegistry;
    }

    function isRootLicense(
        uint256 licenseId_
    ) public view returns (bool) {
        return _getRightsManagerStorage().licenses[licenseId_].parentLicenseId == _UNSET_LICENSE_ID && isLicenseSet(licenseId_);
    }

    function isLicenseSet(uint256 licenseId_) public view returns (bool) {
        return _getRightsManagerStorage().licenses[licenseId_].revoker != address(0);
    }

    
    /// Since the LicenseRegistry tracks sublicense ownership, this method can only be called by the LicenseRegistry.
    /// @dev Throws if the license is not active. Basically exists to not break ERC-5218.
    /// @param licenseId_ the license to transfer
    /// @param licenseHolder_ the new license holder
    function transferSublicense(
        uint256 licenseId_,
        address licenseHolder_
    ) public virtual override(IERC5218) {
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        if (msg.sender != address($.licenseRegistry)) revert Errors.Unauthorized();
        if (!isLicenseActive(licenseId_)) revert Errors.RightsManager_InactiveLicense();
        emit TransferLicense(licenseId_, licenseHolder_);
    }

}
