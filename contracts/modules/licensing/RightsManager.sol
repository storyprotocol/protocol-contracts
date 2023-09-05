// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { LibDuration } from "../timing/LibDuration.sol";
import { UPGRADER_ROLE } from "contracts/access-control/ProtocolRoles.sol";
import { IERC5218 } from "./IERC5218.sol";
import { LicenseRegistry } from "./LicenseRegistry.sol";
import { NonExistentID, Unauthorized, ZeroAddress, UnsupportedInterface } from "contracts/errors/General.sol";
import { IERC165Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import { ERC165CheckerUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { ITermsProcessor } from "./terms/ITermsProcessor.sol";


abstract contract RightsManager is
    ERC721Upgradeable,
    IERC5218
{
    using ERC165CheckerUpgradeable for address;

    error NotOwnerOfParentLicense();
    error InactiveLicense();
    error InactiveParentLicense();
    error CannotSublicense();
    error CommercialTermsMismatch();
    error SenderNotRevoker();
    error NotSublicense();
    error AlreadyHasRootLicense();
    error ZeroRevokerAddress();
    error NFTHasNoAssociatedLicense();
    error UseCreateFranchiseRootLicenseInstead();

    event TermsUpdated(uint256 indexed licenseId, address processor, bytes termsData);

    struct License {
        bool active;
        bool canSublicense;
        bool commercial;
        uint256 parentLicenseId;
        uint256 tokenId;
        address revoker;
        string uri; // NOTE: should we merge this with IPAssetRegistry tokenURI for Licenses who are rights?
        ITermsProcessor termsProcessor;
        bytes termsData;
    }

    struct RightsManagerStorage {
        mapping(uint256 => License) licenses;
        // keccack256(commercial, tokenId) => licenseId
        mapping(bytes32 => uint256) licensesForTokenId;
        uint256 licenseCounter;
        LicenseRegistry licenseRegistry;
    }

    // keccak256(bytes.concat(bytes32(uint256(keccak256("story-protocol.rights-manager.storage")) - 1)))
    bytes32 private constant _STORAGE_LOCATION = 0x315576c20e31e03ef3e70482445a4c33e45baf13beff28e79f2adf6d06cc0bee;
    uint256 private constant _UNSET_LICENSE_ID = 0;
    uint256 public constant FRANCHISE_REGISTRY_OWNED_TOKEN_ID = type(uint256).max;
    IERC721 public immutable FRANCHISE_REGISTRY;


    constructor(address _franchiseRegistry) {
        if (_franchiseRegistry == address(0)) {
            revert ZeroAddress();
        }
        FRANCHISE_REGISTRY = IERC721(_franchiseRegistry);        
    }

    function __RightsManager_init(
        string calldata name,
        string calldata symbol
    ) public initializer {
        __ERC721_init(name, symbol);
        // licenseRegistry should be immutable, but address(this) in the constructor is the interface address, not the proxy address
        // TODO: Revisit this if/when we make IPAssetRegistries immutable
        _getRightsManagerStorage().licenseRegistry = new LicenseRegistry(
            address(this),
            string.concat("Licenses for ", name),
            string.concat("sl", symbol)
        );
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

    function createLicense(
        uint256 _tokenId, // Question: should sublicenses be created with a tokenId or just a parentLicenseId?
        uint256 _parentLicenseId,
        address _licenseHolder,
        string memory _uri,
        address _revoker,
        bool _commercial,
        bool _canSublicense,
        TermsProcessorConfig memory _terms
    ) external override returns (uint256) {
        if (_tokenId == FRANCHISE_REGISTRY_OWNED_TOKEN_ID || _parentLicenseId == _UNSET_LICENSE_ID) {
            revert UseCreateFranchiseRootLicenseInstead();
        }
        if (msg.sender != getLicenseHolder(_parentLicenseId)) revert Unauthorized();
        return _createLicense(
            _tokenId,
            _parentLicenseId,
            _licenseHolder,
            _uri,
            _revoker,
            _commercial,
            _canSublicense,
            _terms,
            true
        );
    }

    function createFranchiseRootLicense(
        uint256 franchiseId,
        address _licenseHolder,
        string memory _uri,
        address _revoker,
        bool _commercial,
        bool _canSublicense,
        TermsProcessorConfig memory _terms
    ) external returns (uint256) {
        if (msg.sender != FRANCHISE_REGISTRY.ownerOf(franchiseId)) revert Unauthorized();
        return _createLicense(
            FRANCHISE_REGISTRY_OWNED_TOKEN_ID,
            _UNSET_LICENSE_ID,
            _licenseHolder,
            _uri,
            _revoker,
            _commercial,
            _canSublicense,
            _terms,
            true
        );
    }

    function _createLicense(
        uint256 tokenId,
        uint256 parentLicenseId,
        address licenseHolder,
        string memory uri,
        address revoker,
        bool commercial,
        bool canSublicense,
        TermsProcessorConfig memory _terms,
        bool inLicenseRegistry
    ) internal returns (uint256) {
        // TODO: should revoker come from allowed revoker list?
        if (revoker == address(0)) revert ZeroRevokerAddress();
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        // Only licenses minted to the FranchiseRegistry Owner as a root license should
        // have tokenId = FRANCHISE_REGISTRY_OWNED_TOKEN_ID, otherwise the tokenId should be a minted NFT (IPAsset)
        // Checks for the FranchiseRegistry Owner should be done in the calling function
        if (tokenId != FRANCHISE_REGISTRY_OWNED_TOKEN_ID) {
            if (!_exists(tokenId)) {
                revert NonExistentID(tokenId);
            }
        }
        // If this is not a LicenseRegsitry license, check that the tokenId doesn't already have a root license
        if (!inLicenseRegistry) {
            if ($.licensesForTokenId[keccak256(abi.encode(commercial, tokenId))] != _UNSET_LICENSE_ID) {
                revert AlreadyHasRootLicense();
            }
        } else if(tokenId != FRANCHISE_REGISTRY_OWNED_TOKEN_ID && parentLicenseId != _UNSET_LICENSE_ID) {
            // If this is a sublicense, check that this is a valid sublicense
            License memory parentLicense = $.licenses[parentLicenseId];
            if (!parentLicense.active) revert InactiveParentLicense();
            if (!parentLicense.canSublicense) revert CannotSublicense();
            if (parentLicense.commercial != commercial) revert CommercialTermsMismatch();
            if (getLicenseHolder(parentLicenseId) != licenseHolder) revert NotOwnerOfParentLicense();
        }
        // Check that the terms are valid
        _verifyTerms(_terms);

        // Create the license and increment the licenseCounter
        uint256 licenseId = ++$.licenseCounter;
        $.licenses[licenseId] = License({
            active: true,
            canSublicense: canSublicense,
            commercial: commercial,
            parentLicenseId: parentLicenseId,
            tokenId: tokenId,
            revoker: revoker,
            uri: uri,
            termsProcessor: _terms.processor,
            termsData: _terms.data
        });
        
        // Mint the license in the LicenseRegistry if requested. Should not do this for IPAsset Rights, but
        // the checks on inLicenseRegistry should be done in the calling function
        if (inLicenseRegistry) {
            $.licenseRegistry.mint(licenseHolder, licenseId);
        } else {
            // Save tokenId => licenseId relationship IF this is a root license
            $.licensesForTokenId[keccak256(abi.encode(commercial, tokenId))] = licenseId;
        }

        // Emit events
        emit CreateLicense(
            licenseId,
            tokenId,
            parentLicenseId,
            licenseHolder,
            uri,
            revoker
        );
        emit TransferLicense(licenseId, licenseHolder);
        return licenseId;
    }

    function revokeLicense(uint256 _licenseId) external override {
        if (!isLicenseSet(_licenseId)) revert NonExistentID(_licenseId);
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        License storage license = $.licenses[_licenseId];
        if (msg.sender != license.revoker) revert SenderNotRevoker();
        license.active = false;
        emit RevokeLicense(_licenseId);
        // TODO: should we burn the license if it's from the LicenseRegistry?
        // TODO: delete the rootLicenseForTokenId mapping for licenseId if root license
    }

    function executeTerms(uint256 _licenseId) external {
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        if (msg.sender != $.licenseRegistry.ownerOf(_licenseId)) revert Unauthorized();
        License storage license = $.licenses[_licenseId];
        if (license.termsProcessor != ITermsProcessor(address(0))) {
            bytes memory newData = license.termsProcessor.executeTerms(license.termsData);
            if (keccak256(license.termsData) != keccak256(newData)) {
                license.termsData = newData;
                emit TermsUpdated(_licenseId, address(license.termsProcessor), newData);
            }
        }
        emit ExecuteTerms(_licenseId, license.termsData);
    }

    function isLicenseActive(
        uint256 licenseId
    ) public view virtual returns (bool) {
        // TODO: limit to the tree depth
        if (licenseId == 0) return false;
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        while (licenseId != 0) {
            License memory license = $.licenses[licenseId];
            if (!_isActiveAndTermsOk(license)) return false;
            licenseId = license.parentLicenseId;
        }
        return true;
    }

    function _isActiveAndTermsOk(License memory license) view private returns (bool) {
        if (address(license.termsProcessor) == address(0)) return license.active;
        return license.active && license.termsProcessor.tersmExecutedSuccessfully(license.termsData);
    }

    function getLicense(uint256 licenseId) public view returns (License memory, address holder) {
        return (
            _getRightsManagerStorage().licenses[licenseId],
            getLicenseHolder(licenseId)
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        if (from != address(0)) {
            for (uint256 i = firstTokenId; i < batchSize;) {
                _verifyRightsTransfer(from, to, i);
                unchecked {
                    i++;
                }
            }
        }
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }
    
    function _verifyRightsTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        // TODO: trigger rights transfer check, check granting terms, banned marketplaces, etc.
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        // NOTE: We are assuming a revoked Non Commercial License impedes the transfer of the NFT.
        // Should revoked commercial rights also impede the transfer?
        uint256 licenseId = $.licensesForTokenId[keccak256(abi.encode(false, tokenId))];
        if (licenseId != _UNSET_LICENSE_ID) revert NFTHasNoAssociatedLicense(); // This should not happen, if fired there is a bug somewhere
        if (isLicenseActive(licenseId)) revert InactiveLicense(); // NOTE: Should we freeze invalid licenses? burn them?
        emit TransferLicense(licenseId, to);
    }

    function _verifyTerms(TermsProcessorConfig memory _terms) private view {
        if  (address(_terms.processor) != address(0) &&
            !_terms.processor.supportsInterface(type(ITermsProcessor).interfaceId)) {
            revert UnsupportedInterface("ITermsProcessor");
        }
    }

    function getLicenseTokenId(
        uint256 _licenseId
    ) external view override returns (uint256) {
        return _getRightsManagerStorage().licenses[_licenseId].tokenId;
    }

    function getParentLicenseId(
        uint256 _licenseId
    ) external view override returns (uint256) {
        return _getRightsManagerStorage().licenses[_licenseId].parentLicenseId;
    }

    function getLicenseHolder(
        uint256 _licenseId
    ) public view override returns (address) {
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        if ($.licenseRegistry.exists(_licenseId)) {
            return $.licenseRegistry.ownerOf(_licenseId);
        } else {
            License storage license = $.licenses[
                _licenseId
            ];
            return ownerOf(license.tokenId);
        }
    }

    function getLicenseURI(
        uint256 _licenseId
    ) external view override returns (string memory) {
        return _getRightsManagerStorage().licenses[_licenseId].uri;
    }

    function getLicenseRevoker(
        uint256 _licenseId
    ) external view override returns (address) {
        return _getRightsManagerStorage().licenses[_licenseId].revoker;
    }

    function getLicenseIdByTokenId(
        uint256 _tokenId,
        bool _commercial
    ) public view override returns (uint256) {
        return
            _getRightsManagerStorage().licensesForTokenId[
                keccak256(abi.encode(_commercial, _tokenId))
            ];
    }

    function getLicenseRegistry() external view returns (LicenseRegistry) {
        return _getRightsManagerStorage().licenseRegistry;
    }

    function isRootLicense(
        uint256 licenseId
    ) public view returns (bool) {
        return _getRightsManagerStorage().licenses[licenseId].parentLicenseId == _UNSET_LICENSE_ID && isLicenseSet(licenseId);
    }

    function isLicenseSet(uint256 licenseId) public view returns (bool) {
        return _getRightsManagerStorage().licenses[licenseId].revoker != address(0);
    }

    function transferSublicense(
        uint256 licenseId,
        address licenseHolder
    ) public virtual override(IERC5218) {
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        if (msg.sender != address($.licenseRegistry)) revert Unauthorized();
        if (!isLicenseActive(licenseId)) revert InactiveLicense();
        emit TransferLicense(licenseId, licenseHolder);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC5218).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}