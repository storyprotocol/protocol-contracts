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
        mapping(bytes32 => uint256) licenseForTokenId;
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
        _getRightsManagerStorage().licenseRegistry = new LicenseRegistry(address(this), "Licenses", "SPLC");
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
        uint256 _tokenId,
        uint256 _parentLicenseId,
        address _licenseHolder, // NOTE: MODIFIED ERC-5218, we should ignore this
        string memory _uri,
        address _revoker,
        bool _commercial,
        bool _canSublicense,
        TermsProcessorConfig memory _terms
    ) external override returns (uint256) {
        // TODO: check if msg.sender is allowed to create license
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
        if (tokenId != FRANCHISE_REGISTRY_OWNED_TOKEN_ID) {
            if (!_exists(tokenId)) {
                revert NonExistentID(tokenId);
            }
        }
        if (parentLicenseId == _UNSET_LICENSE_ID) {
            if ($.licenseForTokenId[keccak256(abi.encode(commercial, tokenId))] != _UNSET_LICENSE_ID) {
                revert AlreadyHasRootLicense();
            }
        } else {
            License memory parentLicense = $.licenses[parentLicenseId];
            _verifySublicense(parentLicenseId, licenseHolder, commercial, parentLicense);
        }
        _verifyTerms(_terms);
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
        $.licenseForTokenId[
            keccak256(abi.encode(commercial, tokenId))
        ] = licenseId;

        if (inLicenseRegistry) {
            $.licenseRegistry.mint(licenseHolder, licenseId);
        }
        emit TransferLicense(licenseId, licenseHolder);
        emit CreateLicense(
            licenseId,
            tokenId,
            parentLicenseId,
            licenseHolder,
            uri,
            revoker
        );
        
        return licenseId;
    }

    function revokeLicense(uint256 _licenseId) external override {
        if (!_exists(_licenseId)) revert NonExistentID(_licenseId);
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        License storage license = $.licenses[_licenseId];
        if (msg.sender != license.revoker) revert SenderNotRevoker();
        license.active = false;
        emit RevokeLicense(_licenseId);
        // TODO: should we burn the license if it's from the LicenseRegistry?
    }

    function executeTerms(uint256 _licenseId) external {
        RightsManagerStorage storage $ = _getRightsManagerStorage();
        if (msg.sender != address($.licenseRegistry)) revert Unauthorized();
        License storage license = $.licenses[_licenseId];
        if (license.termsProcessor != ITermsProcessor(address(0))) {
            bytes memory newData = license.termsProcessor.executeTerms(license.termsData);
            if (keccak256(license.termsData) != keccak256(newData)) {
                license.termsData = newData;
            }
        }
        emit ExecuteTerms(_licenseId, license.termsData);
    }

    function isLicenseActive(
        uint256 licenseId
    ) public view virtual returns (bool) {
        // TODO: limit to the tree depth
        // TODO: check time limits
        if (licenseId == 0) return false;
        while (licenseId != 0) {
            RightsManagerStorage storage $ = _getRightsManagerStorage();
            License memory license = $.licenses[licenseId];
            if (
                !(
                    license.active &&
                    license.termsProcessor.tersmExecutedSuccessfully(license.termsData)
                )
            ) return false;
            licenseId = license.parentLicenseId;
        }
        return true;
    }


    function _verifySublicense(
        uint256 parentLicenseId,
        address licensor,
        bool commercial,
        License memory parentLicense
    ) private view {
        if (ownerOf(parentLicenseId) != licensor) revert NotOwnerOfParentLicense();
        if (!parentLicense.active) revert InactiveParentLicense();
        if (!parentLicense.canSublicense) revert CannotSublicense();
        if (parentLicense.commercial != commercial) revert CommercialTermsMismatch();
    }

    function getLicense(
        uint256 licenseId
    ) public view returns (License memory, address holder) {
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
        // TODO: trigger rights transfer check, check granting terms, banned marketplaces, etc.
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
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
            _getRightsManagerStorage().licenseForTokenId[
                keccak256(abi.encode(_commercial, _tokenId))
            ];
    }

    function getLicenseRegistry() external view returns (LicenseRegistry) {
        return _getRightsManagerStorage().licenseRegistry;
    }

    function isRootLicense(
        uint256 licenseId
    ) public view returns (bool) {
        return _getRightsManagerStorage().licenses[licenseId].parentLicenseId == _UNSET_LICENSE_ID;
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